#!/usr/bin/env python3
import base64
import datetime
import json
import os
import socket
import subprocess
import threading
import time
import urllib.error
import urllib.parse
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

TARGETS = json.loads(os.environ["MONITOR_TARGETS"])
PORT = int(os.environ["MONITOR_PORT"])
STATE_PATH = os.environ["MONITOR_STATE_PATH"]
ALERT_PATH = os.environ["MONITOR_ALERT_PATH"]
GRAFANA_URL = os.environ["GRAFANA_URL"].rstrip("/")
GRAFANA_TOKEN = os.environ["GRAFANA_TOKEN"]
LOKI_URL = os.environ["LOKI_URL"].rstrip("/")
NTFY_TOPIC = os.environ["NTFY_TOPIC"]
NTFY_TOKEN = os.environ["NTFY_TOKEN"]
DEEP_LINK = os.environ["MONITOR_DEEP_LINK"]
CREDS = os.environ["CREDENTIALS_DIRECTORY"]

HOSTS = TARGETS["hosts"]
APPS = TARGETS["apps"]
SUPPRESS = set(TARGETS["suppressAlerts"])
RESTIC_UNIT_QUERY = TARGETS["resticUnitQuery"]

FAST_INTERVAL = 30
SLOW_INTERVAL = 60
LAZY_INTERVAL = 900
TICK = 5
COOLDOWN = 1800
FAST_THRESHOLD = 3
SLOW_THRESHOLD = 2

NODE_JOIN = "* on(instance) group_left(nodename) node_uname_info"
NODE_QUERIES = {
    "load1": f"max by (nodename) (node_load1 {NODE_JOIN})",
    "mem_used": (
        "max by (nodename) ((1 - node_memory_MemAvailable_bytes"
        f" / node_memory_MemTotal_bytes) {NODE_JOIN})"
    ),
    "disk_used": (
        'max by (nodename) ((1 - node_filesystem_avail_bytes{mountpoint="/"}'
        f' / node_filesystem_size_bytes{{mountpoint="/"}}) {NODE_JOIN})'
    ),
    "temp_c": f"max by (nodename) (node_hwmon_temp_celsius {NODE_JOIN})",
}

LOCK = threading.Lock()
SNAPSHOT = {"generated_at": 0, "ready": False}


def credential(name):
    with open(os.path.join(CREDS, name)) as handle:
        return handle.read().strip()


LOKI_AUTH = "Basic " + base64.b64encode(
    ("alloy:" + credential("loki-password")).encode()
).decode()
KUBECONFIG = os.path.join(CREDS, "kubeconfig")
RESTIC_PASSWORD_FILE = os.path.join(CREDS, "restic-password")
RESTIC_REPO = credential("restic-repository")


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


PROBE = urllib.request.build_opener(NoRedirect)


def tcp_probe(address, port, timeout=4):
    started = time.monotonic()
    try:
        with socket.create_connection((address, port), timeout=timeout):
            return {"up": True, "ms": round((time.monotonic() - started) * 1000, 1)}
    except Exception as error:
        return {"up": False, "ms": None, "error": type(error).__name__}


def http_probe(url, timeout=12):
    started = time.monotonic()
    try:
        response = PROBE.open(url, timeout=timeout)
        code = response.getcode()
        response.close()
    except urllib.error.HTTPError as error:
        code = error.code
    except Exception as error:
        return {"up": False, "code": None, "ms": None, "error": type(error).__name__}
    elapsed = round((time.monotonic() - started) * 1000, 1)
    return {"up": code < 500, "code": code, "ms": elapsed}


def grafana(path, params=None):
    url = GRAFANA_URL + path
    if params:
        url += "?" + urllib.parse.urlencode(params)
    request = urllib.request.Request(
        url, headers={"Authorization": "Bearer " + GRAFANA_TOKEN}
    )
    with urllib.request.urlopen(request, timeout=25) as response:
        return json.loads(response.read())


def promql(query):
    payload = grafana(
        "/api/datasources/proxy/uid/prometheus/api/v1/query", {"query": query}
    )
    return payload["data"]["result"]


def node_metrics():
    nodes = {}
    for field, query in NODE_QUERIES.items():
        try:
            for series in promql(query):
                name = series["metric"].get("nodename")
                if not name:
                    continue
                nodes.setdefault(name, {})[field] = float(series["value"][1])
        except Exception as error:
            print(f"promql {field} failed: {error}", flush=True)
    return nodes


def cluster_alerts():
    payload = grafana(
        "/api/datasources/proxy/uid/alertmanager/api/v2/alerts", {"active": "true"}
    )
    active = []
    suppressed = []
    for alert in payload:
        labels = alert.get("labels", {})
        name = labels.get("alertname", "unknown")
        if name in SUPPRESS:
            suppressed.append(name)
            continue
        active.append(
            {
                "alertname": name,
                "severity": labels.get("severity", ""),
                "state": alert.get("status", {}).get("state", ""),
            }
        )
    active.sort(key=lambda item: (item["severity"], item["alertname"]))
    return {"active": active, "suppressed": len(suppressed)}


def kubectl(*args):
    result = subprocess.run(
        ["kubectl", *args],
        capture_output=True,
        text=True,
        timeout=40,
        env=dict(os.environ, KUBECONFIG=KUBECONFIG),
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip()[:200])
    return json.loads(result.stdout)


def kubectl_text(*args):
    result = subprocess.run(
        ["kubectl", *args],
        capture_output=True,
        text=True,
        timeout=40,
        env=dict(os.environ, KUBECONFIG=KUBECONFIG),
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip()[:200])
    return result.stdout


POD_TEMPLATE = (
    "{range .items[*]}{.metadata.namespace}{'\\t'}{.metadata.name}"
    "{'\\t'}{.status.phase}{'\\t'}"
    '{range .status.conditions[?(@.type=="Ready")]}{.status}{end}'
    "{'\\n'}{end}"
)


def problem_pods():
    pods = []
    for line in kubectl_text("get", "pods", "-A", "-o", f"jsonpath={POD_TEMPLATE}").splitlines():
        fields = line.split("\t")
        if len(fields) < 4:
            continue
        namespace, name, phase, ready = fields[0], fields[1], fields[2], fields[3]
        if phase == "Succeeded":
            continue
        if phase == "Running" and ready == "True":
            continue
        pods.append(
            {
                "namespace": namespace,
                "name": name,
                "phase": phase if phase != "Running" else "NotReady",
            }
        )
    return pods


def condition_status(item, wanted="Ready"):
    for condition in item.get("status", {}).get("conditions", []):
        if condition.get("type") == wanted:
            return condition.get("status", "Unknown")
    return "Unknown"


def cluster_state():
    state = {"nodes": [], "pods": [], "flux": []}
    for item in kubectl("get", "nodes", "-o", "json")["items"]:
        state["nodes"].append(
            {
                "name": item["metadata"]["name"],
                "ready": condition_status(item) == "True",
            }
        )
    state["nodes"].sort(key=lambda item: item["name"])
    state["pods"] = problem_pods()
    flux = kubectl(
        "get",
        "kustomizations.kustomize.toolkit.fluxcd.io,helmreleases.helm.toolkit.fluxcd.io",
        "-A",
        "-o",
        "json",
    )
    for item in flux["items"]:
        ready = condition_status(item)
        if ready != "True":
            state["flux"].append(
                {
                    "kind": item["kind"],
                    "namespace": item["metadata"]["namespace"],
                    "name": item["metadata"]["name"],
                    "ready": ready,
                }
            )
    return state


def restic_latest():
    result = subprocess.run(
        ["restic", "snapshots", "--json", "--latest", "1", "--no-cache"],
        capture_output=True,
        text=True,
        timeout=240,
        env=dict(
            os.environ,
            RESTIC_REPOSITORY=RESTIC_REPO,
            RESTIC_PASSWORD_FILE=RESTIC_PASSWORD_FILE,
        ),
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip()[:200])
    snapshots = json.loads(result.stdout)
    if not snapshots:
        return {"age_hours": None, "host": ""}
    latest = snapshots[-1]
    taken = datetime.datetime.fromisoformat(latest["time"])
    if taken.tzinfo is None:
        taken = taken.astimezone()
    now = datetime.datetime.now(datetime.timezone.utc)
    age = (now - taken.astimezone(datetime.timezone.utc)).total_seconds()
    return {"age_hours": round(age / 3600, 1), "host": latest.get("hostname", "")}


def loki_instant(query):
    url = LOKI_URL + "/loki/api/v1/query?" + urllib.parse.urlencode({"query": query})
    request = urllib.request.Request(url, headers={"Authorization": LOKI_AUTH})
    with urllib.request.urlopen(request, timeout=25) as response:
        return json.loads(response.read())["data"]["result"]


def restic_units():
    units = []
    for series in loki_instant(RESTIC_UNIT_QUERY):
        labels = series["metric"]
        units.append(
            {
                "host": labels.get("host", ""),
                "unit": labels.get("unit", ""),
                "lines": int(float(series["value"][1])),
            }
        )
    units.sort(key=lambda item: (item["host"], item["unit"]))
    return units


def local_stats():
    with open("/proc/loadavg") as handle:
        load1 = float(handle.read().split()[0])
    meminfo = {}
    with open("/proc/meminfo") as handle:
        for line in handle:
            key, _, rest = line.partition(":")
            fields = rest.split()
            if fields:
                meminfo[key] = float(fields[0])
    total = meminfo.get("MemTotal") or 1.0
    available = meminfo.get("MemAvailable") or 0.0
    stats = os.statvfs("/")
    return {
        "load1": load1,
        "mem_used": round(1 - available / total, 4),
        "disk_used": round(1 - stats.f_bavail / stats.f_blocks, 4),
    }


def notify(message, priority):
    request = urllib.request.Request(
        "https://ntfy.sh/" + NTFY_TOPIC,
        data=message.encode(),
        headers={
            "Authorization": "Bearer " + NTFY_TOKEN,
            "Title": "BiggerWorld",
            "Priority": priority,
            "Click": DEEP_LINK,
        },
        method="POST",
    )
    try:
        urllib.request.urlopen(request, timeout=15)
        print(f"notified: {message}", flush=True)
    except Exception as error:
        print(f"ntfy failed: {error}", flush=True)


def load_alerts():
    try:
        with open(ALERT_PATH) as handle:
            return json.load(handle)
    except Exception:
        return {}


def save_alerts():
    temp = ALERT_PATH + ".tmp"
    with open(temp, "w") as handle:
        json.dump(ALERTS, handle)
    os.replace(temp, ALERT_PATH)


ALERTS = load_alerts()


def step(key, failing, summary, threshold):
    record = ALERTS.setdefault(key, {"fails": 0, "firing": False, "sent": 0})
    now = time.time()
    if failing:
        record["fails"] += 1
        if record["fails"] < threshold:
            return
        if not record["firing"]:
            notify(summary, "high")
            record["firing"] = True
            record["sent"] = now
        elif now - record["sent"] >= COOLDOWN:
            notify(summary + " (still)", "default")
            record["sent"] = now
        return
    if record["firing"]:
        notify(summary + " recovered", "low")
    record["fails"] = 0
    record["firing"] = False


def evaluate_hosts(state):
    for name, host in state["hosts"].items():
        if host.get("class") != "critical":
            continue
        step("host:" + name, not host["up"], f"{name} unreachable", FAST_THRESHOLD)
    save_alerts()


def evaluate_slow(state):
    for app in state["apps"]:
        if not app.get("alert", True):
            continue
        detail = f"{app['name']} http {app['code']}" if app.get("code") else f"{app['name']} down"
        step("app:" + app["name"], not app["up"], detail, SLOW_THRESHOLD)
    for node in (state.get("cluster") or {}).get("nodes", []):
        step(
            "node:" + node["name"],
            not node["ready"],
            f"node {node['name']} not ready",
            SLOW_THRESHOLD,
        )
    save_alerts()


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def do_GET(self):
        path = urllib.parse.urlparse(self.path).path
        if path in ("/", "/state.json"):
            with LOCK:
                body = json.dumps(SNAPSHOT).encode()
            content = "application/json"
        elif path == "/healthz":
            body = b"ok\n"
            content = "text/plain"
        else:
            self.send_error(404)
            return
        self.send_response(200)
        self.send_header("Content-Type", content)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        return


def serve():
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()


def publish(state):
    temp = STATE_PATH + ".tmp"
    with open(temp, "w") as handle:
        json.dump(state, handle)
    os.replace(temp, STATE_PATH)


threading.Thread(target=serve, daemon=True).start()
print(f"serving on :{PORT}", flush=True)

STATE = {
    "hosts": {},
    "apps": [],
    "nodes": {},
    "cluster": None,
    "alerts": None,
    "backups": None,
    "local": {},
    "errors": {},
}
DEADLINES = {"fast": 0.0, "slow": 0.0, "lazy": 0.0}

while True:
    moment = time.monotonic()

    if moment >= DEADLINES["fast"]:
        DEADLINES["fast"] = moment + FAST_INTERVAL
        probed = {}
        for name, host in HOSTS.items():
            if host["class"] == "ignore":
                continue
            result = tcp_probe(host["ip"], host.get("port", 22))
            result["class"] = host["class"]
            probed[name] = result
        STATE["hosts"] = probed
        try:
            STATE["local"] = local_stats()
        except Exception as error:
            STATE["errors"]["local"] = str(error)[:200]
        evaluate_hosts(STATE)

    if moment >= DEADLINES["slow"]:
        DEADLINES["slow"] = moment + SLOW_INTERVAL
        checked = []
        for app in APPS:
            result = http_probe(app["url"])
            result["name"] = app["name"]
            result["alert"] = app.get("alert", True)
            checked.append(result)
        STATE["apps"] = checked
        STATE["nodes"] = node_metrics()
        for label, action in (("alerts", cluster_alerts), ("cluster", cluster_state)):
            try:
                STATE[label] = action()
                STATE["errors"].pop(label, None)
            except Exception as error:
                STATE["errors"][label] = str(error)[:200]
        evaluate_slow(STATE)

    if moment >= DEADLINES["lazy"]:
        DEADLINES["lazy"] = moment + LAZY_INTERVAL
        backups = dict(STATE["backups"] or {})
        for label, action in (("amateus", restic_latest), ("units", restic_units)):
            try:
                backups[label] = action()
                STATE["errors"].pop("restic-" + label, None)
            except Exception as error:
                STATE["errors"]["restic-" + label] = str(error)[:200]
        STATE["backups"] = backups

    STATE["generated_at"] = time.time()
    STATE["ready"] = True
    with LOCK:
        SNAPSHOT.clear()
        SNAPSHOT.update(STATE)
    try:
        publish(STATE)
    except Exception as error:
        print(f"publish failed: {error}", flush=True)

    time.sleep(TICK)
