#!/usr/bin/env python3
import curses
import locale
import json
import os
import sys
import threading
import time
import urllib.request

STATE_URL = os.environ["DISPLAY_STATE_URL"]
FETCH_INTERVAL = int(os.environ["DISPLAY_FETCH_INTERVAL"])
STALE_AFTER = int(os.environ["DISPLAY_STALE_AFTER"])
DEAD_AFTER = int(os.environ["DISPLAY_DEAD_AFTER"])
NTFY_TOPIC = os.environ["NTFY_TOPIC"]
NTFY_TOKEN = os.environ["NTFY_TOKEN"]
NTFY_URL = os.environ["NTFY_URL"]
NTFY_FALLBACK_URL = os.environ["NTFY_FALLBACK_URL"]
DEEP_LINK = os.environ["DISPLAY_DEEP_LINK"]

COOLDOWN = 1800
STALE_HOURS = 36
OK = "ok"
WARN = "warn"
BAD = "bad"
HEAD = "head"
DIM = "dim"

PAIRS = {OK: 1, WARN: 2, BAD: 3, HEAD: 4, DIM: 5}

LOCK = threading.Lock()
LATEST = {"state": None, "fetched": 0.0, "error": None}
WATCHDOG = {"firing": False, "sent": 0.0}


def fetch_once():
    request = urllib.request.Request(STATE_URL)
    with urllib.request.urlopen(request, timeout=5) as response:
        return json.loads(response.read())


def notify(message, priority):
    for base, token in ((NTFY_URL, None), (NTFY_FALLBACK_URL, NTFY_TOKEN)):
        headers = {
            "Title": "BiggerWorld",
            "Priority": priority,
            "Click": DEEP_LINK,
        }

        if token:
            headers["Authorization"] = "Bearer " + token

        request = urllib.request.Request(
            base + "/" + NTFY_TOPIC,
            data=message.encode(),
            headers=headers,
            method="POST",
        )

        try:
            urllib.request.urlopen(request, timeout=10)
            print(f"notified via {base}: {message}", file=sys.stderr, flush=True)
            return
        except Exception as error:
            print(f"ntfy failed at {base}: {error}", file=sys.stderr, flush=True)


def watchdog(age):
    now = time.time()
    if age is not None and age < DEAD_AFTER:
        if WATCHDOG["firing"]:
            notify("collector recovered", "low")
        WATCHDOG["firing"] = False
        return

    if not WATCHDOG["firing"]:
        notify("collector stale, no state from algol", "high")
        WATCHDOG["firing"] = True
        WATCHDOG["sent"] = now
    elif now - WATCHDOG["sent"] >= COOLDOWN:
        notify("collector still stale", "default")
        WATCHDOG["sent"] = now


def poller():
    while True:
        try:
            state = fetch_once()
            with LOCK:
                LATEST["state"] = state
                LATEST["fetched"] = time.time()
                LATEST["error"] = None
        except Exception as error:
            with LOCK:
                LATEST["error"] = type(error).__name__
        with LOCK:
            state = LATEST["state"]
            generated = (state or {}).get("generated_at") or 0
        age = time.time() - generated if generated else None
        watchdog(age)
        time.sleep(FETCH_INTERVAL)


def local_stats():
    try:
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
        root = os.statvfs("/")
        srv = os.statvfs("/srv")
        return {
            "load1": load1,
            "mem_used": 1 - available / total,
            "disk_used": 1 - root.f_bavail / root.f_blocks,
            "srv_used": 1 - srv.f_bavail / srv.f_blocks,
        }
    except Exception:
        return None


def pct(value):
    if value is None:
        return "   -"
    return f"{value * 100:3.0f}%"


def level(value, warn, bad):
    if value is None:
        return DIM
    if value >= bad:
        return BAD
    if value >= warn:
        return WARN
    return OK


SECTION_LIMIT = {
    "hosts": 120,
    "apps": 210,
    "nodes": 210,
    "cluster": 900,
    "flux": 210,
    "alerts": 210,
    "backups": 2700,
    "disks": 2700,
}

FLUX_NAMES = {
    "apps-config": "A-configs",
    "flux-system": "flux-sys",
}


def compact(age):
    if age < 90:
        return f"{int(age)}s"
    if age < 5400:
        return f"{int(age / 60)}m"
    return f"{int(age / 3600)}h"


def panel(state, label, section):
    stamp = ((state or {}).get("updated_at") or {}).get(section)
    if not stamp:
        return (f"{label}  (pending)", WARN)
    age = time.time() - stamp
    if age > SECTION_LIMIT[section]:
        return (f"{label}  (stale {compact(age)})", BAD)
    return (label, HEAD)
def build_hosts(state):
    rows = [panel(state, "HOSTS", "hosts")]
    hosts = (state or {}).get("hosts") or {}
    for name in sorted(hosts):
        host = hosts[name]
        mark = "up  " if host.get("up") else "DOWN"
        colour = OK if host.get("up") else (BAD if host.get("class") == "critical" else WARN)
        latency = host.get("ms")
        shown = f"{latency:6.1f}ms" if latency is not None else "       -"
        rows.append((f"  {name:<10} {mark} {shown}", colour))
    return rows


def build_nodes(state):
    rows = [("", DIM), panel(state, "CLUSTER NODES", "nodes"),
            ("  node        load   mem  disk  temp", DIM)]
    nodes = (state or {}).get("nodes") or {}
    for name in sorted(nodes):
        node = nodes[name]
        load = node.get("load1")
        temp = node.get("temp_c")
        rows.append((
            f"  {name:<10} {load if load is not None else 0:5.2f}"
            f"  {pct(node.get('mem_used'))}  {pct(node.get('disk_used'))}"
            f"  {temp if temp is not None else 0:3.0f}C",
            level(node.get("mem_used"), 0.85, 0.95),
        ))
    return rows


def build_local(state):
    rows = [("", DIM), ("THIS HOST", HEAD)]
    stats = local_stats()
    if not stats:
        rows.append(("  unavailable", WARN))
        return rows
    rows.append((
        f"  load {stats['load1']:.2f}   mem {pct(stats['mem_used'])}"
        f"   / {pct(stats['disk_used'])}   /srv {pct(stats['srv_used'])}",
        level(max(stats["disk_used"], stats["srv_used"]), 0.85, 0.95),
    ))
    return rows


def build_apps(state):
    rows = [panel(state, "APPS", "apps")]
    for app in (state or {}).get("apps") or []:
        code = app.get("code")
        shown = str(code) if code else "---"
        latency = app.get("ms")
        timing = f"{latency:7.1f}ms" if latency is not None else "        -"
        rows.append((
            f"  {app['name']:<11} {shown:>4} {timing}",
            OK if app.get("up") else BAD,
        ))
    return rows


PHASE_SHORT = {
    "CrashLoopBackOff": "CrashLoop",
    "ImagePullBackOff": "ImagePull",
    "ErrImagePull": "ImageErr",
    "CreateContainerConfigError": "ConfigErr",
    "ContainerCreating": "Creating",
}


def short_phase(phase):
    return PHASE_SHORT.get(phase, phase)[:10]


def label_of(entry):
    label = f"{entry['namespace']}/{entry['name']}"
    if len(label) <= 24:
        return label
    return label[:23] + "~"


def build_cluster(state):
    rows = [("", DIM), panel(state, "CLUSTER", "cluster")]
    cluster = (state or {}).get("cluster")
    if not cluster:
        rows.append(("  unavailable", WARN))
        return rows
    ready = [node for node in cluster.get("nodes", []) if node.get("ready")]
    total = cluster.get("nodes", [])
    rows.append((
        f"  nodes ready   {len(ready)}/{len(total)}",
        OK if len(ready) == len(total) and total else BAD,
    ))
    for node in total:
        flags = list(node.get("pressure") or [])
        if node.get("cordoned"):
            flags.insert(0, "cordoned")
        if flags:
            rows.append((f"    {node['name']} {','.join(flags)}", WARN))

    workloads = (state or {}).get("workloads") or {}
    counts = workloads.get("counts") or {}
    for kind, label in (
        ("Deployment", "deploys"),
        ("StatefulSet", "stateful"),
        ("DaemonSet", "daemon"),
    ):
        bucket = counts.get(kind)
        if not bucket:
            continue
        rows.append((
            f"  {label:<13} {bucket['ready']}/{bucket['total']}",
            OK if bucket["ready"] == bucket["total"] else BAD,
        ))
    for entry in (workloads.get("degraded") or [])[:4]:
        rows.append((
            f"    {label_of(entry):<24} {entry['ready']}/{entry['desired']}",
            BAD,
        ))

    pods = cluster.get("pods", [])
    known = cluster.get("pod_count") or 0
    tally = f"{len(pods)}/{known}" if known else str(len(pods))
    rows.append((f"  pods bad      {tally}", OK if not pods else BAD))
    for pod in pods[:4]:
        rows.append((
            f"    {label_of(pod):<22} {short_phase(pod['phase'])}",
            BAD,
        ))

    restarting = cluster.get("restarting") or []
    if restarting:
        rows.append((f"  restarting    {len(restarting)}", WARN))
        for pod in restarting[:3]:
            rows.append((
                f"    {label_of(pod):<24} x{pod['restarts']}",
                WARN,
            ))
    return rows


def build_flux(state):
    rows = [("", DIM), panel(state, "FLUX", "flux")]
    flux = (state or {}).get("flux")
    if not flux:
        rows.append(("  unavailable", WARN))
        return rows
    drift = flux.get("drift") or {}
    sources = flux.get("sources") or {}
    source = list(sources.values())[0] if sources else {}
    pending = drift.get("pending") or []
    if drift.get("stuck"):
        label, colour = "STUCK", BAD
    elif drift.get("in_sync"):
        label, colour = "in sync", OK
    else:
        label, colour = f"{len(pending)} pending", WARN
    rows.append((f"  source     {source.get('short') or '-':<11} {label}", colour))
    for entry in flux.get("kustomizations") or []:
        age = compact(entry.get("drift_age") or 0)
        note = ""
        if entry.get("suspended"):
            mark, colour = "susp", WARN
        elif entry.get("ready") != "True":
            mark, colour = "FAIL", BAD
        elif entry.get("stuck"):
            mark, colour, note = "ok  ", BAD, f"stuck {age}"
        elif entry.get("drifted"):
            mark, colour, note = "ok  ", WARN, f"behind {age}"
        else:
            mark, colour = "ok  ", OK
        applied = (entry.get("applied") or "").rsplit(":", 1)[-1][:7] or "-"
        rows.append((
            f"  {FLUX_NAMES.get(entry['name'], entry['name'])[:14]:<14}"
            f" {mark} {applied:<8} {note}",
            colour,
        ))
    broken = [
        entry
        for entry in flux.get("helmreleases") or []
        if not entry.get("suspended") and entry.get("ready") != "True"
    ]
    for entry in broken[:3]:
        rows.append((f"  {entry['namespace']}/{entry['name'][:22]} FAIL", BAD))
    for slot in (flux.get("timeline") or [])[:4]:
        ok = slot.get("status") == "ReconciliationSucceeded"
        names = ", ".join(
            FLUX_NAMES.get(name, name) for name in slot.get("resources") or []
        )[:34]
        rows.append((
            f"    {slot['revision']:<8} {slot['duration']:5.1f}s  {names}",
            DIM if ok else BAD,
        ))
    return rows


def build_alerts(state):
    rows = [("", DIM), panel(state, "ALERTS", "alerts")]
    alerts = (state or {}).get("alerts")
    if not alerts:
        rows.append(("  unavailable", WARN))
        return rows
    active = alerts.get("active", [])
    rows.append((
        f"  active {len(active)}   suppressed {alerts.get('suppressed', 0)}",
        OK if not active else WARN,
    ))
    for alert in active[:6]:
        severity = alert.get("severity", "")
        colour = BAD if severity in ("critical", "warning") else WARN
        rows.append((f"    {alert['alertname'][:28]:<28} {severity}", colour))
    return rows


def size(value):
    if value is None:
        return "-"
    scaled = float(value)
    for suffix in ("B", "K", "M", "G", "T"):
        if scaled < 1024 or suffix == "T":
            return f"{scaled:.0f}{suffix}"
        scaled /= 1024
    return "-"


def build_backups(state):
    rows = [("", DIM), panel(state, "BACKUPS", "backups")]
    backups = (state or {}).get("backups")
    if not backups:
        rows.append(("  unavailable", WARN))
        return rows

    groups = backups.get("groups") or []
    repo = backups.get("repo") or {}
    if groups:
        oldest = max(groups, key=lambda group: group["age_hours"])
        late = [group for group in groups if group["age_hours"] > STALE_HOURS]
        dead = [group for group in groups if group["age_hours"] > STALE_HOURS * 2]
        rows.append((
            f"  sets {len(groups)}  oldest {oldest['age_hours']:.0f}h"
            f"  {size(repo.get('size'))}",
            BAD if dead else (WARN if late else OK),
        ))
        for group in sorted(late, key=lambda group: -group["age_hours"])[:4]:
            rows.append((
                f"    {group['host']:<9} {group['age_hours']:.0f}h stale",
                BAD if group["age_hours"] > STALE_HOURS * 2 else WARN,
            ))
    else:
        amateus = backups.get("amateus") or {}
        age = amateus.get("age_hours")
        if age is None:
            rows.append(("  no snapshot found", BAD))
        else:
            rows.append((
                f"  last snapshot {age:.1f}h ago  ({amateus.get('host', '?')})",
                OK if age < STALE_HOURS else (WARN if age < STALE_HOURS * 2 else BAD),
            ))

    units = backups.get("units") or []
    failing = [unit for unit in units if not unit.get("ok", True)]
    if units:
        rows.append((
            f"  units {len(units) - len(failing)}/{len(units)} clean",
            BAD if failing else OK,
        ))
        for unit in failing[:4]:
            rows.append((f"    {unit['host']:<9} {unit['unit'][:16]}", BAD))
    return rows


def build_disks(state):
    rows = [("", DIM), panel(state, "DISKS", "disks")]
    disks = (state or {}).get("disks")
    if not disks:
        rows.append(("  unavailable", WARN))
        return rows
    failing = sorted(
        name for name, disk in disks.items() if not disk.get("ok", True)
    )
    rows.append((
        f"  {len(disks) - len(failing)}/{len(disks)} hosts clear",
        BAD if failing else OK,
    ))
    for name in failing[:4]:
        rows.append((
            f"    {name:<9} {disks[name].get('fails', 0)} warnings 24h",
            BAD,
        ))
    return rows


def compose(state):
    left = (
        build_hosts(state)
        + build_nodes(state)
        + build_cluster(state)
        + build_local(state)
        + build_backups(state)
        + build_disks(state)
    )
    right = (
        build_apps(state)
        + build_flux(state)
        + build_alerts(state)
    )
    return left, right


def header(state, age, error):
    stamp = time.strftime("%Y-%m-%d %H:%M")
    if state is None:
        return f"BIGGERWORLD   {stamp}   NO STATE", BAD
    if age is None or age > STALE_AFTER:
        shown = f"{int(age)}s" if age is not None else "never"
        return f"BIGGERWORLD   {stamp}   STALE {shown}", BAD
    if error:
        return f"BIGGERWORLD   {stamp}   fetch {error}", WARN
    return f"BIGGERWORLD   {stamp}   live", OK


def put(window, y, x, text, attr):
    rows, cols = window.getmaxyx()
    if y < 0 or y >= rows or x >= cols - 1:
        return
    window.addnstr(y, x, text, cols - x - 1, attr)


def draw(window, signature):
    with LOCK:
        state = LATEST["state"]
        fetched = LATEST["fetched"]
        error = LATEST["error"]
    generated = (state or {}).get("generated_at") or 0
    age = time.time() - generated if generated else None
    title, title_colour = header(state, age, error)
    left, right = compose(state)

    rows, cols = window.getmaxyx()
    split = max(38, cols // 2)
    footer = STATE_URL
    if fetched:
        footer = (
            time.strftime("updated %H:%M:%S", time.localtime(fetched))
            + "   "
            + STATE_URL
        )
    fresh = [title, str(rows), str(cols), footer]
    fresh += [text for text, _ in left] + ["|"] + [text for text, _ in right]
    joined = "\n".join(fresh)
    if joined == signature:
        return signature


    window.erase()
    frame = curses.color_pair(PAIRS[HEAD])
    width = cols - 1
    put(window, 0, 0, "┌" + "─" * (width - 2) + "┐", frame)
    put(window, 2, 0, "├" + "─" * (width - 2) + "┤", frame)
    put(window, rows - 1, 0, "└" + "─" * (width - 2) + "┘", frame)
    for offset in list(range(1, 2)) + list(range(3, rows - 1)):
        put(window, offset, 0, "│", frame)
        put(window, offset, width - 1, "│", frame)

    put(window, 1, 2, title, curses.color_pair(PAIRS[title_colour]) | curses.A_BOLD)

    for offset in range(3, rows - 1):
        put(window, offset, split, "│", frame)

    for index, (text, colour) in enumerate(left):
        attr = curses.color_pair(PAIRS[colour])
        if colour == HEAD:
            attr |= curses.A_BOLD
        put(window, 3 + index, 2, text[: split - 3], attr)

    for index, (text, colour) in enumerate(right):
        attr = curses.color_pair(PAIRS[colour])
        if colour == HEAD:
            attr |= curses.A_BOLD
        put(window, 3 + index, split + 2, text, attr)

    put(window, rows - 2, 2, footer, curses.color_pair(PAIRS[DIM]))
    window.noutrefresh()
    curses.doupdate()
    return joined


def main(window):
    curses.start_color()
    curses.init_pair(PAIRS[OK], curses.COLOR_GREEN, curses.COLOR_BLACK)
    curses.init_pair(PAIRS[WARN], curses.COLOR_YELLOW, curses.COLOR_BLACK)
    curses.init_pair(PAIRS[BAD], curses.COLOR_RED, curses.COLOR_BLACK)
    curses.init_pair(PAIRS[HEAD], curses.COLOR_CYAN, curses.COLOR_BLACK)
    curses.init_pair(PAIRS[DIM], curses.COLOR_WHITE, curses.COLOR_BLACK)
    curses.curs_set(0)
    window.nodelay(True)

    threading.Thread(target=poller, daemon=True).start()

    signature = None
    while True:
        try:
            signature = draw(window, signature)
        except curses.error:
            signature = None
        time.sleep(1)


locale.setlocale(locale.LC_ALL, "")
curses.wrapper(main)
