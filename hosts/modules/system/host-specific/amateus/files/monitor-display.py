#!/usr/bin/env python3
import curses
import json
import locale
import os
import sys
import threading
import time
import urllib.error
import urllib.request

STATE_URL = os.environ["DISPLAY_STATE_URL"]
FETCH_INTERVAL = int(os.environ["DISPLAY_FETCH_INTERVAL"])
STALE_AFTER = int(os.environ["DISPLAY_STALE_AFTER"])
DEAD_AFTER = int(os.environ["DISPLAY_DEAD_AFTER"])
AGENTS = json.loads(os.environ["DISPLAY_AGENTS"])
AGENT_TOKEN = os.environ["DISPLAY_AGENT_TOKEN"]
AGENT_STALE_AFTER = int(os.environ["DISPLAY_AGENT_STALE_AFTER"])
STALE_HOURS = float(os.environ["DISPLAY_BACKUP_STALE_HOURS"])
NTFY_TOPIC = os.environ["NTFY_TOPIC"]
NTFY_TOKEN = os.environ["NTFY_TOKEN"]
NTFY_URL = os.environ["NTFY_URL"]
NTFY_FALLBACK_URL = os.environ["NTFY_FALLBACK_URL"]
DEEP_LINK = os.environ["DISPLAY_DEEP_LINK"]

COOLDOWN = 1800
OK = "ok"
WARN = "warn"
BAD = "bad"
HEAD = "head"
DIM = "dim"

PAIRS = {OK: 1, WARN: 2, BAD: 3, HEAD: 4, DIM: 5}
RANK = {DIM: 0, OK: 1, WARN: 2, BAD: 3}
PRIORITY_RANK = {"critical": 0, "watch": 1, "ignore": 2}

BLOCKS = "░▒▓█"
SPARK_WIDTH = 16

CPU_TEMP_WARN = 80.0
CPU_TEMP_BAD = 90.0
GPU_TEMP_WARN = 85.0
GPU_TEMP_BAD = 95.0
DISK_TEMP_WARN = 55.0
DISK_TEMP_BAD = 65.0

LOCK = threading.Lock()
LATEST = {"state": None, "fetched": 0.0, "error": None}
WATCHDOG = {"firing": False, "sent": 0.0}

AGENT_LOCK = threading.Lock()
AGENT_STATE = {
    entry["host"]: {"stats": None, "error": "pending", "fetched": 0.0}
    for entry in AGENTS
}
AGENT_HOSTS = {entry["host"] for entry in AGENTS}


def worst(*states):
    return max(states, key=lambda state: RANK.get(state, 0))


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
        notify("collector stale, no state from aperture", "high")
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


def fetch_agent(entry):
    request = urllib.request.Request(
        entry["url"].rstrip("/") + "/stats",
        headers={"Authorization": "Bearer " + AGENT_TOKEN},
    )
    with urllib.request.urlopen(request, timeout=4) as response:
        return json.loads(response.read())


def agent_poller(entry):
    host = entry["host"]
    while True:
        try:
            stats = fetch_agent(entry)
            with AGENT_LOCK:
                AGENT_STATE[host] = {
                    "stats": stats,
                    "error": None,
                    "fetched": time.time(),
                }
        except urllib.error.HTTPError as error:
            note = "rejected" if error.code in (401, 403) else f"HTTP {error.code}"
            with AGENT_LOCK:
                AGENT_STATE[host]["error"] = note
        except Exception as error:
            with AGENT_LOCK:
                AGENT_STATE[host]["error"] = type(error).__name__
        time.sleep(FETCH_INTERVAL)


def pct(value, width=4):
    if value is None:
        return "--%".rjust(width)
    return f"{value * 100:.0f}%".rjust(width)


def size(value):
    if value is None:
        return "-"
    scaled = float(value)
    for suffix in ("B", "K", "M", "G", "T", "P"):
        if scaled < 1024 or suffix == "P":
            return f"{scaled:.0f}{suffix}"
        scaled /= 1024
    return "-"


def temp(value):
    return "--C" if value is None else f"{value:.0f}C"


def level(value, warn, bad):
    if value is None:
        return DIM
    if value >= bad:
        return BAD
    if value >= warn:
        return WARN
    return OK


def compact(age):
    if age < 90:
        return f"{int(age)}s"
    if age < 5400:
        return f"{int(age / 60)}m"
    if age < 172800:
        return f"{int(age / 3600)}h"
    return f"{int(age / 86400)}d"


def uptime_label(seconds):
    if seconds is None:
        return "-"
    days, rest = divmod(int(seconds), 86400)
    hours, rest = divmod(rest, 3600)
    minutes = rest // 60
    if days:
        return f"{days}d {hours}h"
    if hours:
        return f"{hours}h {minutes}m"
    return f"{minutes}m"


def spark(series, width, floor=0.0, ceiling=1.0):
    values = list(series or [])
    if not values:
        return " " * width
    span = len(values) / width
    scale = (ceiling - floor) or 1.0
    out = ""
    for index in range(width):
        start = int(index * span)
        stop = max(int((index + 1) * span), start + 1)
        chunk = [value for value in values[start:stop] if value is not None]
        if not chunk:
            out += " "
            continue
        position = (sum(chunk) / len(chunk) - floor) / scale
        position = min(max(position, 0.0), 1.0)
        out += BLOCKS[min(int(position * len(BLOCKS)), len(BLOCKS) - 1)]
    return out


def pack(cells, room):
    out = ""
    for index, cell in enumerate(cells):
        candidate = cell if not out else out + "   " + cell
        if len(candidate) > room:
            return (out or cell[:room]) + f"  +{len(cells) - index}"
        out = candidate
    return out


def serial_tail(disk):
    name = disk.get("name") or ""
    tail = name.rsplit("_", 1)[-1] if "_" in name else name
    return (tail[-7:] or "?")


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


def panel(state, label, section):
    stamp = ((state or {}).get("updated_at") or {}).get(section)
    if not stamp:
        return (f"{label}  (pending)", WARN)
    age = time.time() - stamp
    if age > SECTION_LIMIT[section]:
        return (f"{label}  (stale {compact(age)})", BAD)
    return (label, HEAD)


def host_body(stats, width):
    rows = []
    status = DIM
    history = stats.get("history") or {}
    room = width - 7

    cpu = stats.get("cpu") or {}
    usage = cpu.get("usage")
    load1 = cpu.get("load1")
    cores = cpu.get("cores") or 0
    cpu_temp = cpu.get("temp_c")
    cpu_status = worst(
        level(usage, 0.85, 0.95),
        level(cpu_temp, CPU_TEMP_WARN, CPU_TEMP_BAD),
    )
    status = worst(status, cpu_status)
    rows.append((
        f"  cpu  {spark(history.get('cpu_usage'), SPARK_WIDTH)} {pct(usage)}"
        f"   load {load1 if load1 is not None else 0:5.2f}/{cores:<3}"
        f" {temp(cpu_temp):>5}",
        cpu_status,
    ))

    memory = stats.get("memory") or {}
    used = memory.get("used")
    total = memory.get("total")
    available = memory.get("available")
    swap = memory.get("swap_used")
    consumed = total - available if total and available is not None else None
    mem_status = worst(level(used, 0.85, 0.95), level(swap, 0.5, 0.8))
    status = worst(status, mem_status)
    rows.append((
        f"  mem  {spark(history.get('mem_used'), SPARK_WIDTH)} {pct(used)}"
        f"   {size(consumed):>5}/{size(total):<5}"
        f"  swap {pct(swap)}",
        mem_status,
    ))

    filesystems = stats.get("filesystems") or []
    if filesystems:
        fs_status = OK
        cells = []
        for entry in filesystems:
            fs_status = worst(fs_status, level(entry.get("used"), 0.85, 0.95))
            cells.append(f"{entry.get('mount') or '?'} {pct(entry.get('used'))}")
        status = worst(status, fs_status)
        rows.append(("  fs   " + pack(cells, room), fs_status))

    gpus = stats.get("gpus") or []
    if gpus:
        gpu_status = DIM
        cells = []
        for entry in gpus:
            gpu_status = worst(
                gpu_status,
                level(entry.get("temp_c"), GPU_TEMP_WARN, GPU_TEMP_BAD),
            )
            cells.append(
                f"{entry.get('model') or entry.get('name') or '?'}"
                f" {pct(entry.get('usage'))}"
                f" vram {pct(entry.get('vram_used'))}/{size(entry.get('vram_total'))}"
                f" {temp(entry.get('temp_c'))}"
            )
        status = worst(status, gpu_status)
        rows.append(("  gpu  " + pack(cells, room), gpu_status))

    disks = stats.get("disks") or []
    if disks:
        disk_status = OK
        flagged = []
        for entry in disks:
            health = entry.get("health")
            each = worst(
                BAD if health and health != "PASSED" else OK,
                level(entry.get("temp_c"), DISK_TEMP_WARN, DISK_TEMP_BAD),
            )
            disk_status = worst(disk_status, each)
            if each != OK:
                note = "" if health == "PASSED" else f" {health or '?'}"
                flagged.append(f"{serial_tail(entry)} {temp(entry.get('temp_c'))}{note}")
        status = worst(status, disk_status)
        summary = f"{len(disks) - len(flagged)}/{len(disks)} clear"
        rows.append(("  disk " + pack([summary] + flagged, room), disk_status))

    return rows, status


def host_card(entry, width):
    host = entry["host"]
    priority = entry.get("priority") or "watch"
    with AGENT_LOCK:
        record = dict(AGENT_STATE.get(host) or {})
    stats = record.get("stats")
    error = record.get("error")

    if not stats:
        status = BAD if priority == "critical" else WARN
        return [(
            f"{host.upper():<11} {priority:<9} {error or 'unreachable'}",
            status,
        )], status

    rows, status = host_body(stats, width)
    age = time.time() - (stats.get("at") or 0)
    notes = []
    if age > AGENT_STALE_AFTER:
        notes.append(f"stale {compact(age)}")
        status = worst(status, WARN)
    if error:
        notes.append(error)
        status = worst(status, WARN)
    probe = stats.get("errors") or {}
    if probe:
        notes.append(",".join(sorted(probe))[:24])

    head = f"{host.upper():<11} {priority:<9} up {uptime_label(stats.get('uptime'))}"
    if notes:
        head = f"{head:<40}" + "   ".join(notes)
    return [(head, status)] + rows, status


def compact_card(entry, width):
    card, status = host_card(entry, width)
    host = entry["host"]
    with AGENT_LOCK:
        stats = (AGENT_STATE.get(host) or {}).get("stats")
    if not stats:
        return card, status
    cpu = stats.get("cpu") or {}
    memory = stats.get("memory") or {}
    disks = stats.get("disks") or []
    root = next(
        (entry["used"] for entry in stats.get("filesystems") or []
         if entry.get("mount") == "/"),
        None,
    )
    return [(
        f"{host.upper():<10} {pct(cpu.get('usage'))} {temp(cpu.get('temp_c')):>5}"
        f" {pct(memory.get('used'))} {pct(root)} {len(disks)}d",
        status,
    )], status


def build_fleet(width):
    renderer = host_card if width >= 60 else compact_card
    cards = []
    for entry in AGENTS:
        rows, status = renderer(entry, width)
        cards.append((entry, status, rows))
    cards.sort(key=lambda item: (
        PRIORITY_RANK.get(item[0].get("priority"), 1),
        -RANK.get(item[1], 0),
        item[0]["host"],
    ))
    rows = [("FLEET", HEAD)]
    for _, _, card in cards:
        rows.append(("", DIM))
        rows.extend(card)
    return rows


def build_reach(state):
    rows = [panel(state, "REACHABILITY", "hosts")]
    hosts = (state or {}).get("hosts") or {}
    agentless = [name for name in sorted(hosts) if name not in AGENT_HOSTS]
    if not agentless:
        rows.append(("  every host has an agent", DIM))
        return rows
    for name in agentless:
        host = hosts[name]
        up = host.get("up")
        mark = "up  " if up else "DOWN"
        colour = OK if up else (BAD if host.get("class") == "critical" else WARN)
        latency = host.get("ms")
        shown = f"{latency:6.1f}ms" if latency is not None else "       -"
        rows.append((f"  {name:<10} {mark} {shown}", colour))
    return rows


def build_apps(state):
    rows = [("", DIM), panel(state, "APPS", "apps")]
    apps = (state or {}).get("apps") or []
    if not apps:
        rows.append(("  unavailable", WARN))
        return rows
    down = [app for app in apps if not app.get("up")]
    rows.append((
        f"  {len(apps) - len(down)}/{len(apps)} up",
        OK if not down else BAD,
    ))
    for app in down[:6]:
        code = app.get("code")
        shown = str(code) if code else "---"
        latency = app.get("ms")
        timing = f"{latency:7.1f}ms" if latency is not None else "        -"
        rows.append((f"    {app['name']:<13} {shown:>4} {timing}", BAD))
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
    for slot in (flux.get("timeline") or [])[:3]:
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
    for alert in active[:5]:
        severity = alert.get("severity", "")
        colour = BAD if severity in ("critical", "warning") else WARN
        rows.append((f"    {alert['alertname'][:28]:<28} {severity}", colour))
    return rows


def build_backups(state):
    rows = [("", DIM), panel(state, "BACKUPS", "backups")]
    backups = (state or {}).get("backups")
    if not backups:
        rows.append(("  unavailable", WARN))
        return rows

    groups = backups.get("groups") or []
    repo = backups.get("repo") or {}
    if groups:
        tracked = [group for group in groups if group.get("expected", True)]
        retired = len(groups) - len(tracked)
        scope = tracked or groups
        oldest = max(scope, key=lambda group: group["age_hours"])
        late = [group for group in tracked if group["age_hours"] > STALE_HOURS]
        dead = [group for group in tracked if group["age_hours"] > STALE_HOURS * 2]
        note = f"  +{retired} retired" if retired else ""
        rows.append((
            f"  sets {len(tracked)}  oldest {oldest['age_hours']:.0f}h"
            f"  {size(repo.get('size'))}{note}",
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


def compose(state, width):
    left = build_fleet(width)
    right = (
        build_reach(state)
        + build_apps(state)
        + build_cluster(state)
        + build_flux(state)
        + build_alerts(state)
        + build_backups(state)
    )
    return left, right


def header(state, age, error):
    stamp = time.strftime("%Y-%m-%d %H:%M")
    with AGENT_LOCK:
        live = sum(1 for record in AGENT_STATE.values() if record.get("stats"))
    tally = f"agents {live}/{len(AGENTS)}"
    agent_colour = OK if live == len(AGENTS) else (BAD if not live else WARN)

    if state is None:
        return f"BIGGERWORLD   {stamp}   NO STATE   {tally}", BAD
    if age is None or age > STALE_AFTER:
        shown = f"{int(age)}s" if age is not None else "never"
        return f"BIGGERWORLD   {stamp}   STALE {shown}   {tally}", BAD
    if error:
        return f"BIGGERWORLD   {stamp}   fetch {error}   {tally}", WARN
    return f"BIGGERWORLD   {stamp}   live   {tally}", agent_colour


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

    rows, cols = window.getmaxyx()
    split = max(38, cols // 2)
    left, right = compose(state, split - 3)

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
    for entry in AGENTS:
        threading.Thread(target=agent_poller, args=(entry,), daemon=True).start()

    signature = None
    while True:
        try:
            signature = draw(window, signature)
        except curses.error:
            signature = None
        time.sleep(1)


locale.setlocale(locale.LC_ALL, "")
curses.wrapper(main)
