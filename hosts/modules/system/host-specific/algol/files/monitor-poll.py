#!/usr/bin/env python3
import base64
import concurrent.futures
import datetime
import html
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

with open(os.environ["MONITOR_PAGE"]) as handle:
    PAGE_TEMPLATE = handle.read()

HOSTS = TARGETS["hosts"]
APPS = TARGETS["apps"]
SUPPRESS = set(TARGETS["suppressAlerts"])
RESTIC_UNIT_QUERY = TARGETS["resticUnitQuery"]
DRIFT_TIMEOUT = TARGETS["driftTimeout"]
HISTORY_DEPTH = TARGETS["historyDepth"]
TIMELINE_DEPTH = TARGETS["timelineDepth"]

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
    failures = []
    for field, query in NODE_QUERIES.items():
        try:
            for series in promql(query):
                name = series["metric"].get("nodename")
                if not name:
                    continue
                nodes.setdefault(name, {})[field] = float(series["value"][1])
        except Exception as error:
            failures.append(f"{field}: {error}")
            print(f"promql {field} failed: {error}", flush=True)
    if len(failures) == len(NODE_QUERIES):
        raise RuntimeError("; ".join(failures)[:200])
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


def condition_detail(item, wanted="Ready"):
    for condition in item.get("status", {}).get("conditions", []):
        if condition.get("type") == wanted:
            return (
                condition.get("reason", ""),
                condition.get("message", ""),
                condition.get("lastTransitionTime", ""),
            )
    return ("", "", "")


def short_revision(revision):
    if not revision:
        return ""
    return revision.rsplit(":", 1)[-1][:7]


def parse_stamp(stamp):
    if not stamp:
        return None
    try:
        return datetime.datetime.fromisoformat(stamp.replace("Z", "+00:00")).timestamp()
    except Exception:
        return None


def cluster_state():
    state = {"nodes": [], "pods": []}
    for item in kubectl("get", "nodes", "-o", "json")["items"]:
        state["nodes"].append(
            {
                "name": item["metadata"]["name"],
                "ready": condition_status(item) == "True",
            }
        )
    state["nodes"].sort(key=lambda item: item["name"])
    state["pods"] = problem_pods()
    return state


def history_entries(item):
    entries = []
    for record in (item.get("status", {}).get("history") or [])[:HISTORY_DEPTH]:
        if item["kind"] == "HelmRelease":
            entries.append(
                {
                    "revision": record.get("chartVersion", ""),
                    "status": record.get("status", ""),
                    "at": record.get("lastDeployed", ""),
                    "duration": "",
                    "count": record.get("version"),
                }
            )
        else:
            entries.append(
                {
                    "revision": short_revision(
                        (record.get("metadata") or {}).get("revision")
                    ),
                    "status": record.get("lastReconciledStatus", ""),
                    "at": record.get("lastReconciled", ""),
                    "duration": record.get("lastReconciledDuration", ""),
                    "count": record.get("totalReconciliations"),
                }
            )
    return entries


def flux_source(item):
    artifact = item.get("status", {}).get("artifact") or {}
    spec = item.get("spec") or {}
    return {
        "namespace": item["metadata"]["namespace"],
        "name": item["metadata"]["name"],
        "url": spec.get("url", ""),
        "interval": spec.get("interval", ""),
        "revision": artifact.get("revision", ""),
        "short": short_revision(artifact.get("revision", "")),
        "artifact_at": parse_stamp(artifact.get("lastUpdateTime")),
        "ready": condition_status(item),
    }


def flux_common(item):
    status = item.get("status") or {}
    spec = item.get("spec") or {}
    reason, message, changed_at = condition_detail(item)
    return {
        "kind": item["kind"],
        "namespace": item["metadata"]["namespace"],
        "name": item["metadata"]["name"],
        "ready": condition_status(item),
        "reason": reason,
        "message": message[:300],
        "changed_at": changed_at,
        "suspended": bool(spec.get("suspend")),
        "interval": spec.get("interval", ""),
        "applied": status.get("lastAppliedRevision", ""),
        "attempted": status.get("lastAttemptedRevision", ""),
        "history": history_entries(item),
    }


def flux_timeline(kustomizations):
    merged = {}
    for entry in kustomizations:
        for record in entry["history"]:
            revision = record["revision"]
            if not revision:
                continue
            slot = merged.setdefault(
                revision,
                {
                    "revision": revision,
                    "at": "",
                    "status": record["status"],
                    "resources": [],
                    "duration": 0.0,
                },
            )
            slot["resources"].append(entry["name"])
            slot["duration"] += parse_duration(record["duration"])
            if record["at"] > slot["at"]:
                slot["at"] = record["at"]
            if record["status"] != "ReconciliationSucceeded":
                slot["status"] = record["status"]
    for slot in merged.values():
        slot["resources"].sort()
    timeline = sorted(merged.values(), key=lambda slot: slot["at"], reverse=True)
    return timeline[:TIMELINE_DEPTH]


def flux_state():
    listing = kubectl(
        "get",
        ",".join(
            [
                "gitrepositories.source.toolkit.fluxcd.io",
                "kustomizations.kustomize.toolkit.fluxcd.io",
                "helmreleases.helm.toolkit.fluxcd.io",
            ]
        ),
        "-A",
        "-o",
        "json",
    )
    sources = {}
    kustomizations = []
    helmreleases = []
    for item in listing["items"]:
        if item["kind"] == "GitRepository":
            source = flux_source(item)
            sources[f"{source['namespace']}/{source['name']}"] = source
        elif item["kind"] == "Kustomization":
            kustomizations.append(item)
        elif item["kind"] == "HelmRelease":
            helmreleases.append(item)

    built = []
    for item in kustomizations:
        entry = flux_common(item)
        spec = item.get("spec") or {}
        source_ref = spec.get("sourceRef") or {}
        entry["path"] = spec.get("path", "")
        entry["source"] = (
            f"{source_ref.get('namespace', entry['namespace'])}/"
            f"{source_ref.get('name', '')}"
        )
        source = sources.get(entry["source"]) or {}
        entry["source_revision"] = source.get("revision", "")
        entry["partial"] = bool(
            entry["attempted"] and entry["attempted"] != entry["applied"]
        )
        if entry["suspended"] or not entry["source_revision"] or not entry["applied"]:
            entry["drifted"] = False
            entry["drift_age"] = None
        else:
            entry["drifted"] = entry["applied"] != entry["source_revision"]
            artifact_at = source.get("artifact_at")
            entry["drift_age"] = (
                max(0.0, time.time() - artifact_at)
                if entry["drifted"] and artifact_at
                else None
            )
        entry["stuck"] = bool(
            entry["drift_age"] is not None and entry["drift_age"] > DRIFT_TIMEOUT
        )
        built.append(entry)
    built.sort(key=lambda entry: (entry["namespace"], entry["name"]))

    releases = []
    for item in helmreleases:
        entry = flux_common(item)
        status = item.get("status") or {}
        spec = item.get("spec") or {}
        recent = entry["history"][0] if entry["history"] else {}
        entry["chart"] = ((spec.get("chart") or {}).get("spec") or {}).get("chart", "")
        entry["wanted"] = ((spec.get("chart") or {}).get("spec") or {}).get(
            "version", ""
        )
        entry["version"] = recent.get("revision", "")
        entry["release"] = recent.get("count")
        entry["action"] = status.get("lastAttemptedReleaseAction", "")
        entry["failures"] = status.get("failures", 0)
        entry["upgrade_failures"] = status.get("upgradeFailures", 0)
        releases.append(entry)
    releases.sort(key=lambda entry: (entry["namespace"], entry["name"]))

    active = [entry for entry in built if not entry["suspended"]]
    pending = [entry["name"] for entry in active if entry["drifted"]]
    revisions = {entry["source_revision"] for entry in active}
    return {
        "sources": sources,
        "kustomizations": built,
        "helmreleases": releases,
        "timeline": flux_timeline(built),
        "drift": {
            "revision": revisions.pop() if len(revisions) == 1 else "",
            "pending": sorted(pending),
            "stuck": any(entry["stuck"] for entry in active),
            "in_sync": not pending,
        },
        "counts": {
            "total": len(built) + len(releases),
            "failing": len(
                [
                    entry
                    for entry in built + releases
                    if not entry["suspended"] and entry["ready"] != "True"
                ]
            ),
            "suspended": len(
                [entry for entry in built + releases if entry["suspended"]]
            ),
            "drifted": len(pending),
        },
    }

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


ALERT_LOCK = threading.Lock()
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


def evaluate_hosts(hosts):
    with ALERT_LOCK:
        for name, host in hosts.items():
            if host.get("class") != "critical":
                continue
            step("host:" + name, not host["up"], f"{name} unreachable", FAST_THRESHOLD)
        save_alerts()


def evaluate_slow(apps, cluster):
    with ALERT_LOCK:
        for app in apps:
            if not app.get("alert", True):
                continue
            detail = (
                f"{app['name']} http {app['code']}"
                if app.get("code")
                else f"{app['name']} down"
            )
            step("app:" + app["name"], not app["up"], detail, SLOW_THRESHOLD)
        for node in (cluster or {}).get("nodes", []):
            step(
                "node:" + node["name"],
                not node["ready"],
                f"node {node['name']} not ready",
                SLOW_THRESHOLD,
            )
        save_alerts()


def parse_duration(text):
    if not text:
        return 0.0
    try:
        if text.endswith("ms"):
            return float(text[:-2]) / 1000
        if text.endswith("s"):
            return float(text[:-1])
    except Exception:
        return 0.0
    return 0.0


def step_once(key, firing, summary, priority):
    record = ALERTS.setdefault(key, {"firing": False})
    if firing and not record["firing"]:
        notify(summary, priority)
        record["firing"] = True
    elif not firing and record["firing"]:
        notify(summary + " resumed", "low")
        record["firing"] = False


HELM_REASONS = ("UpgradeFailed", "InstallFailed", "TestFailed", "RollbackFailed")


def flux_failure(entry):
    key = f"{entry['kind']}/{entry['namespace']}/{entry['name']}"
    label = f"{entry['namespace']}/{entry['name']}"
    helm = entry["kind"] == "HelmRelease" and entry.get("reason") in HELM_REASONS
    if helm:
        action = entry.get("action") or "release"
        return ("fluxhelm:" + key, f"{label} helm {action} failed")
    reason = entry.get("reason") or "not ready"
    return ("flux:" + key, f"{label} {reason}")


def announce_deploy(flux):
    drift = flux["drift"]
    revision = drift["revision"]
    record = ALERTS.setdefault("flux:applied", {})
    if not revision or not drift["in_sync"]:
        return
    active = [
        entry for entry in flux["kustomizations"] if not entry["suspended"]
    ]
    if not active or any(entry["ready"] != "True" for entry in active):
        return
    if record.get("revision") == revision:
        return
    seeded = "revision" in record
    record["revision"] = revision
    if not seeded:
        return
    short = short_revision(revision)
    elapsed = 0.0
    for entry in active:
        for history in entry["history"]:
            if history["revision"] == short:
                elapsed += parse_duration(history["duration"])
                break
    notify(
        f"deployed {short} - {len(active)} kustomizations, {elapsed:.1f}s",
        "low",
    )


def prune_alerts(live):
    prefixes = ("flux:", "fluxhelm:", "fluxsuspend:", "fluxdrift:")
    for name in [name for name in ALERTS if name.startswith(prefixes)]:
        if name != "flux:applied" and name not in live:
            del ALERTS[name]


def evaluate_flux(flux):
    if not flux or not flux.get("counts"):
        return
    resources = flux["kustomizations"] + flux["helmreleases"]
    with ALERT_LOCK:
        live = set()
        for entry in resources:
            key = f"{entry['kind']}/{entry['namespace']}/{entry['name']}"
            label = f"{entry['namespace']}/{entry['name']}"
            suspended = entry["suspended"]
            step_once(
                "fluxsuspend:" + key,
                suspended,
                f"{label} suspended",
                "low",
            )
            live.add("fluxsuspend:" + key)
            failure_key, summary = flux_failure(entry)
            live.add(failure_key)
            step(
                failure_key,
                not suspended and entry["ready"] != "True",
                summary,
                SLOW_THRESHOLD,
            )
            if entry["kind"] == "Kustomization":
                live.add("fluxdrift:" + key)
                step(
                    "fluxdrift:" + key,
                    entry["stuck"],
                    f"{label} stuck on {short_revision(entry['applied'])}",
                    1,
                )
        announce_deploy(flux)
        prune_alerts(live)
        save_alerts()


def escape(value):
    if value is None:
        return "-"
    return html.escape(str(value), quote=True)


def ago(seconds):
    if seconds is None:
        return "-"
    seconds = max(0.0, seconds)
    if seconds < 90:
        return f"{int(seconds)}s"
    if seconds < 5400:
        return f"{int(seconds / 60)}m"
    if seconds < 172800:
        return f"{int(seconds / 3600)}h"
    return f"{int(seconds / 86400)}d"


def since(stamp):
    moment = parse_stamp(stamp)
    if moment is None:
        return "-"
    return ago(time.time() - moment)


def mark(entry):
    if entry["suspended"]:
        return ("susp", "warn")
    if entry["ready"] == "True":
        return ("ok", "ok")
    if entry["ready"] == "Unknown":
        return ("?", "warn")
    return ("fail", "bad")


def pretty_duration(text):
    seconds = parse_duration(text)
    if not seconds:
        return "-"
    if seconds < 1:
        return f"{int(seconds * 1000)}ms"
    return f"{seconds:.1f}s"


def span(value, style):
    return f'<span class="{style}">{escape(value)}</span>'


def row(*cells):
    return "<div>" + "".join(cells) + "</div>"


def section(label):
    return f'<div class="sect">{escape(label)}</div>'


def message_row(entry):
    if entry["suspended"] or entry["ready"] == "True" or not entry["message"]:
        return ""
    return f'<div class="msg">{escape(entry["message"])}</div>'


def render_source(flux):
    sources = flux.get("sources") or {}
    drift = flux["drift"]
    if not sources:
        return row(span("no gitrepository found", "bad"))
    source = list(sources.values())[0]
    if drift["stuck"]:
        label, style = "stuck", "bad"
    elif drift["in_sync"]:
        label, style = "in sync", "ok"
    else:
        label, style = f"{len(drift['pending'])} pending", "warn"
    artifact = ago(time.time() - source["artifact_at"]) if source["artifact_at"] else None
    lines = [
        row(
            span("flux", "key"),
            span(source["short"], "rev"),
            span(label, f"note {style}"),
            span(artifact, "meta"),
        ),
        row(
            span("", "key"),
            span(source["url"], "dim"),
            span(f'every {source["interval"]}', "tail dim"),
        ),
    ]
    if drift["pending"]:
        lines.append(
            row(
                span("", "key"),
                span("waiting: " + ", ".join(drift["pending"]), "warn"),
            )
        )
    return "".join(lines)


def render_kustomizations(flux):
    if not flux["kustomizations"]:
        return row(span("none", "dim"))
    lines = []
    for entry in flux["kustomizations"]:
        glyph, style = mark(entry)
        if entry["drifted"]:
            note = f"behind {ago(entry['drift_age'])}"
            note_style = "bad" if entry["stuck"] else "warn"
        elif entry["suspended"]:
            note, note_style = "suspended", "warn"
        else:
            note, note_style = "in sync", "dim"
        recent = entry["history"][0] if entry["history"] else {}
        lines.append(
            row(
                span(entry["name"], "key"),
                span(glyph, f"st {style}"),
                span(short_revision(entry["applied"]) or "-", "rev"),
                span(note, f"note {note_style}"),
                span(since(recent.get("at")), "meta"),
                span(
                    f'{pretty_duration(recent.get("duration"))} / {recent.get("count") or "-"}',
                    "tail dim",
                ),
            )
        )
        lines.append(message_row(entry))
    return "".join(lines)


def render_helmreleases(flux):
    if not flux["helmreleases"]:
        return row(span("none", "dim"))
    lines = []
    for entry in flux["helmreleases"]:
        glyph, style = mark(entry)
        failures = (entry.get("upgrade_failures") or 0) + (entry.get("failures") or 0)
        note = f"rel {entry.get('release') or '-'}"
        note_style = "dim"
        if entry["suspended"]:
            note, note_style = "suspended", "warn"
        elif entry["ready"] != "True" and failures:
            note, note_style = f"{failures} failures", "bad"
        lines.append(
            row(
                span(f"{entry['namespace']}/{entry['name']}", "key"),
                span(glyph, f"st {style}"),
                span(entry.get("version") or "-", "rev"),
                span(note, f"note {note_style}"),
                span(since(entry.get("changed_at")), "meta"),
                span(entry.get("chart") or "-", "tail dim"),
            )
        )
        lines.append(message_row(entry))
    return "".join(lines)


def render_timeline(flux):
    if not flux["timeline"]:
        return row(span("no history", "dim"))
    lines = []
    for slot in flux["timeline"]:
        ok = slot["status"] == "ReconciliationSucceeded"
        lines.append(
            row(
                span(slot["revision"], "key"),
                span("ok" if ok else "fail", "st " + ("ok" if ok else "bad")),
                span(f'{since(slot["at"])} ago', "rev"),
                span(f'{slot["duration"]:.1f}s', "note dim"),
                span(", ".join(slot["resources"]), "tail dim"),
            )
        )
    return "".join(lines)


def render_page(snapshot):
    flux = snapshot.get("flux")
    errors = snapshot.get("errors") or {}
    updated = (snapshot.get("updated_at") or {}).get("flux")
    generated = snapshot.get("generated_at") or 0
    age = time.time() - generated if generated else None
    parts = []
    if age is not None and age > 90:
        parts.append(row(span(f"collector stale {ago(age)}", "bad")))
    if errors.get("flux"):
        parts.append(row(span(f'query failed: {errors["flux"]}', "bad")))
    if not flux:
        parts.append(row(span("no flux data yet", "warn")))
        return PAGE_TEMPLATE.replace("{{body}}", "".join(parts))
    if updated and time.time() - updated > 210:
        parts.append(
            row(span(f"flux data stale {ago(time.time() - updated)}", "bad"))
        )
    counts = flux["counts"]
    parts.append(render_source(flux))
    parts.append(section("kustomizations"))
    parts.append(render_kustomizations(flux))
    parts.append(section("helmreleases"))
    parts.append(render_helmreleases(flux))
    parts.append(section("timeline"))
    parts.append(render_timeline(flux))
    parts.append(
        row(
            span("", "key"),
            span(
                f'{counts["total"]} resources, {counts["failing"]} failing, '
                f'{counts["drifted"]} pending, {counts["suspended"]} suspended',
                "dim",
            ),
        )
    )
    return PAGE_TEMPLATE.replace("{{body}}", "".join(parts))


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def respond(self, code, body, content):
        self.send_response(code)
        self.send_header("Content-Type", content)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        path = urllib.parse.urlparse(self.path).path
        if path == "/state.json":
            with LOCK:
                body = json.dumps(SNAPSHOT).encode()
            self.respond(200, body, "application/json")
            return
        if path == "/healthz":
            self.respond(200, b"ok\n", "text/plain; charset=utf-8")
            return
        if path in ("/", "/flux"):
            with LOCK:
                snapshot = dict(SNAPSHOT)
                snapshot["updated_at"] = dict(SNAPSHOT.get("updated_at") or {})
                snapshot["errors"] = dict(SNAPSHOT.get("errors") or {})
            try:
                body = render_page(snapshot).encode()
            except Exception as error:
                print(f"render failed: {error}", flush=True)
                self.respond(500, b"render failed\n", "text/plain; charset=utf-8")
                return
            self.respond(200, body, "text/html; charset=utf-8")
            return
        self.send_error(404)

    def log_message(self, fmt, *args):
        return


def serve():
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()


def publish(state):
    temp = STATE_PATH + ".tmp"
    with open(temp, "w") as handle:
        json.dump(state, handle)
    os.replace(temp, STATE_PATH)


STATE = {
    "hosts": {},
    "apps": [],
    "nodes": {},
    "cluster": None,
    "flux": None,
    "alerts": None,
    "backups": None,
    "local": {},
    "errors": {},
    "updated_at": {},
    "tier_ms": {},
}


def commit(section, value):
    with LOCK:
        STATE[section] = value
        STATE["updated_at"][section] = time.time()


def record_error(key, error):
    with LOCK:
        if error is None:
            STATE["errors"].pop(key, None)
        else:
            STATE["errors"][key] = str(error)[:200]


def spread(jobs, workers):
    results = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as pool:
        futures = {pool.submit(action): key for key, action in jobs}
        for future in concurrent.futures.as_completed(futures):
            key = futures[future]
            try:
                results[key] = (future.result(), None)
            except Exception as error:
                results[key] = (None, error)
    return results


def fast_tier():
    active = {
        name: host for name, host in HOSTS.items() if host["class"] != "ignore"
    }
    jobs = [
        (name, lambda host=host: tcp_probe(host["ip"], host.get("port", 22)))
        for name, host in active.items()
    ]
    probed = {}
    for name, (value, error) in spread(jobs, 12).items():
        probed[name] = value or {"up": False, "error": str(error)[:200]}
        probed[name]["class"] = active[name]["class"]
    commit("hosts", probed)

    try:
        commit("local", local_stats())
        record_error("local", None)
    except Exception as error:
        record_error("local", error)

    evaluate_hosts(probed)


def slow_tier():
    jobs = [
        (index, lambda app=app: http_probe(app["url"]))
        for index, app in enumerate(APPS)
    ]
    checked = [None] * len(APPS)
    for index, (value, error) in spread(jobs, 12).items():
        result = value or {"up": False, "code": None, "error": str(error)[:200]}
        result["name"] = APPS[index]["name"]
        result["alert"] = APPS[index].get("alert", True)
        checked[index] = result
    commit("apps", checked)

    outcomes = spread(
        [
            ("nodes", node_metrics),
            ("alerts", cluster_alerts),
            ("cluster", cluster_state),
            ("flux", flux_state),
        ],
        4,
    )
    for label, (value, error) in outcomes.items():
        if error is None:
            commit(label, value)
        record_error(label, error)

    with LOCK:
        cluster = STATE["cluster"]
        flux = STATE["flux"]
    evaluate_slow(checked, cluster)
    evaluate_flux(flux)


def lazy_tier():
    outcomes = spread([("amateus", restic_latest), ("units", restic_units)], 2)
    backups = dict(STATE["backups"] or {})
    for label, (value, error) in outcomes.items():
        if error is None:
            backups[label] = value
        record_error("restic-" + label, error)
    commit("backups", backups)


def run_tier(label, action, interval):
    while True:
        started = time.monotonic()
        try:
            action()
            record_error("tier-" + label, None)
        except Exception as error:
            record_error("tier-" + label, error)
            print(f"tier {label} failed: {error}", flush=True)
        elapsed = time.monotonic() - started
        with LOCK:
            STATE["tier_ms"][label] = round(elapsed * 1000)
        time.sleep(max(1.0, interval - elapsed))


threading.Thread(target=serve, daemon=True).start()
print(f"serving on :{PORT}", flush=True)

for label, action, interval in (
    ("fast", fast_tier, FAST_INTERVAL),
    ("slow", slow_tier, SLOW_INTERVAL),
    ("lazy", lazy_tier, LAZY_INTERVAL),
):
    threading.Thread(target=run_tier, args=(label, action, interval), daemon=True).start()

while True:
    with LOCK:
        STATE["generated_at"] = time.time()
        STATE["ready"] = bool(STATE["updated_at"])
        SNAPSHOT.clear()
        SNAPSHOT.update(STATE)
        state = dict(STATE)
    try:
        publish(state)
    except Exception as error:
        print(f"publish failed: {error}", flush=True)
    time.sleep(TICK)
