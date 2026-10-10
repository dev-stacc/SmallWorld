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
DEEP_LINK = os.environ["DISPLAY_DEEP_LINK"]

COOLDOWN = 1800
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
        urllib.request.urlopen(request, timeout=10)
        print(f"notified: {message}", file=sys.stderr, flush=True)
    except Exception as error:
        print(f"ntfy failed: {error}", file=sys.stderr, flush=True)


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


def build_hosts(state):
    rows = [("HOSTS", HEAD)]
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
    rows = [("", DIM), ("CLUSTER NODES", HEAD),
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
    rows = [("APPS", HEAD)]
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


def build_cluster(state):
    rows = [("", DIM), ("CLUSTER", HEAD)]
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
    pods = cluster.get("pods", [])
    rows.append((f"  pods bad      {len(pods)}", OK if not pods else BAD))
    for pod in pods[:4]:
        rows.append((f"    {pod['namespace']}/{pod['name'][:24]} {pod['phase']}", BAD))
    flux = cluster.get("flux", [])
    rows.append((f"  flux unready  {len(flux)}", OK if not flux else BAD))
    for item in flux[:4]:
        rows.append((f"    {item['namespace']}/{item['name'][:24]}", BAD))
    return rows


def build_alerts(state):
    rows = [("", DIM), ("ALERTS", HEAD)]
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


def build_backups(state):
    rows = [("", DIM), ("BACKUPS", HEAD)]
    backups = (state or {}).get("backups")
    if not backups:
        rows.append(("  unavailable", WARN))
        return rows
    amateus = backups.get("amateus") or {}
    age = amateus.get("age_hours")
    if age is None:
        rows.append(("  no snapshot found", BAD))
    else:
        rows.append((
            f"  last snapshot {age:.1f}h ago  ({amateus.get('host', '?')})",
            OK if age < 36 else (WARN if age < 72 else BAD),
        ))
    for unit in (backups.get("units") or [])[:4]:
        rows.append((f"    {unit['host']:<9} {unit['unit'][:40]}", DIM))
    return rows


def compose(state):
    left = (
        build_hosts(state)
        + build_nodes(state)
        + build_local(state)
        + build_backups(state)
    )
    right = build_apps(state) + build_cluster(state) + build_alerts(state)
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
