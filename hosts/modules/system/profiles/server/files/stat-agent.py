import hmac
import json
import os
import socket
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = int(os.environ["AGENT_PORT"])
BIND = os.environ["AGENT_BIND"]
SMART_PATH = os.environ["AGENT_SMART_PATH"]
INTERVAL = int(os.environ.get("AGENT_INTERVAL", "15"))
DEPTH = int(os.environ.get("AGENT_DEPTH", "240"))
TREND_BUCKET = int(os.environ.get("AGENT_TREND_BUCKET", "300"))
TREND_DEPTH = int(os.environ.get("AGENT_TREND_DEPTH", "2016"))
TREND_PATH = os.environ.get("AGENT_TREND_PATH", "")
HOST = socket.gethostname().lower()

CREDS = os.environ.get("CREDENTIALS_DIRECTORY")
TOKEN = ""
if CREDS:
    with open(os.path.join(CREDS, "token")) as handle:
        TOKEN = handle.read().strip()

SERIES = ("cpu_usage", "mem_used", "cpu_temp_c", "gpu_usage")

LOCK = threading.Lock()
HISTORY = {key: [] for key in SERIES}
TREND = {key: [] for key in SERIES}
PENDING = {key: [] for key in SERIES}
TREND_SLOT = {"value": None}
PREVIOUS = {"total": 0.0, "idle": 0.0}

SKIP_FS = {
    "proc", "sysfs", "devtmpfs", "tmpfs", "devpts", "cgroup2", "pstore",
    "efivarfs", "bpf", "tracefs", "debugfs", "mqueue", "hugetlbfs",
    "configfs", "fusectl", "securityfs", "ramfs", "autofs", "binfmt_misc",
    "nsfs", "overlay", "squashfs",
}


def read(path):
    with open(path) as handle:
        return handle.read()


def cpu_times():
    fields = read("/proc/stat").split("\n")[0].split()[1:]
    values = [float(value) for value in fields]
    idle = values[3] + (values[4] if len(values) > 4 else 0.0)
    return sum(values), idle


def cpu_usage():
    total, idle = cpu_times()
    delta_total = total - PREVIOUS["total"]
    delta_idle = idle - PREVIOUS["idle"]
    PREVIOUS["total"], PREVIOUS["idle"] = total, idle
    if delta_total <= 0:
        return None
    return round(max(0.0, min(1.0, 1 - delta_idle / delta_total)), 4)


CPU_CHIPS = ("coretemp", "k10temp", "zenpower", "cpu_thermal")
PACKAGE_LABELS = ("package id 0", "tctl", "tdie")

def hwmon_chips():
    root = "/sys/class/hwmon"
    try:
        names = sorted(os.listdir(root))
    except OSError:
        return []
    chips = []
    for name in names:
        path = os.path.join(root, name)
        try:
            chip = read(os.path.join(path, "name")).strip().lower()
        except OSError:
            chip = ""
        chips.append((chip, path))
    return chips


def chip_temps(path):
    readings = []
    try:
        entries = sorted(os.listdir(path))
    except OSError:
        return readings
    for entry in entries:
        if not entry.startswith("temp") or not entry.endswith("_input"):
            continue
        try:
            value = int(read(os.path.join(path, entry)).strip()) / 1000
        except (OSError, ValueError):
            continue
        if value <= 0 or value > 150:
            continue
        label = ""
        try:
            label = read(
                os.path.join(path, entry.replace("_input", "_label"))
            ).strip().lower()
        except OSError:
            pass
        readings.append((label, value))
    return readings


def hwmon_temp():
    chips = [(chip, chip_temps(path)) for chip, path in hwmon_chips()]

    for chip, readings in chips:
        for label, value in readings:
            if chip in CPU_CHIPS and label in PACKAGE_LABELS:
                return round(value, 1)

    for chip, readings in chips:
        for label, value in readings:
            if label == "cpu":
                return round(value, 1)

    best = None
    for chip, readings in chips:
        if chip not in CPU_CHIPS:
            continue
        for _, value in readings:
            if best is None or value > best:
                best = value
    if best is not None:
        return round(best, 1)

    for chip, readings in chips:
        if chip != "acpitz":
            continue
        for _, value in readings:
            return round(value, 1)

    return None
def loadavg():
    parts = read("/proc/loadavg").split()
    return [float(parts[0]), float(parts[1]), float(parts[2])]


def meminfo():
    values = {}
    for line in read("/proc/meminfo").splitlines():
        key, _, rest = line.partition(":")
        values[key] = int(rest.split()[0]) * 1024
    total = values.get("MemTotal", 0)
    available = values.get("MemAvailable", 0)
    swap_total = values.get("SwapTotal", 0)
    swap_free = values.get("SwapFree", 0)
    return {
        "total": total or None,
        "available": available or None,
        "used": round(1 - available / total, 4) if total else None,
        "swap_total": swap_total or None,
        "swap_used": (
            round(1 - swap_free / swap_total, 4) if swap_total else None
        ),
    }


def filesystems():
    seen_mounts = set()
    seen_devices = set()
    entries = []
    for line in read("/proc/mounts").splitlines():
        parts = line.split()
        if len(parts) < 4:
            continue
        device, mount, kind = parts[0], parts[1].replace("\\040", " "), parts[2]
        options = parts[3].split(",")
        if kind in SKIP_FS or not device.startswith("/dev/"):
            continue
        if mount in seen_mounts:
            continue
        if device in seen_devices and "ro" in options:
            continue
        seen_mounts.add(mount)
        seen_devices.add(device)
        try:
            stat = os.statvfs(mount)
        except OSError:
            continue
        total = stat.f_blocks * stat.f_frsize
        if total == 0:
            continue
        free = stat.f_bavail * stat.f_frsize
        used = total - stat.f_bfree * stat.f_frsize
        entries.append({
            "mount": mount,
            "device": device,
            "total": total,
            "used_bytes": used,
            "used": round(1 - free / total, 4),
        })
    entries.sort(key=lambda item: item["mount"])
    return entries
def drm_cards():
    try:
        return sorted(
            name for name in os.listdir("/sys/class/drm")
            if name.startswith("card") and name[4:].isdigit()
        )
    except OSError:
        return []


def card_temp(device):
    hwmon = os.path.join(device, "hwmon")
    try:
        for entry in os.listdir(hwmon):
            path = os.path.join(hwmon, entry, "temp1_input")
            if os.path.exists(path):
                return round(int(read(path).strip()) / 1000, 1)
    except (OSError, ValueError):
        pass
    return None


def card_number(device, name, scale=1):
    try:
        return int(read(os.path.join(device, name)).strip()) * scale
    except (OSError, ValueError):
        return None


def card_model(device):
    try:
        return read(os.path.join(device, "product_name")).strip()
    except OSError:
        pass
    try:
        for line in read(os.path.join(device, "uevent")).splitlines():
            key, _, value = line.partition("=")
            if key == "DRIVER":
                return value.strip()
    except OSError:
        pass
    return ""


def gpus():
    found = []
    for card in drm_cards():
        device = os.path.join("/sys/class/drm", card, "device")
        busy = card_number(device, "gpu_busy_percent")
        vram_total = card_number(device, "mem_info_vram_total")
        vram_used = card_number(device, "mem_info_vram_used")
        power = card_number(device, "hwmon/hwmon0/power1_average")
        model = card_model(device)
        found.append({
            "name": card,
            "model": model,
            "usage": None if busy is None else round(busy / 100, 4),
            "vram_total": vram_total,
            "vram_used": (
                round(vram_used / vram_total, 4)
                if vram_total and vram_used is not None
                else None
            ),
            "temp_c": card_temp(device),
            "power_w": None if power is None else round(power / 1000000, 1),
        })
    return found


def smart():
    try:
        payload = json.loads(read(SMART_PATH))
    except (OSError, ValueError) as error:
        return [], {"smart": str(error)[:200]}
    return payload.get("disks") or [], payload.get("errors") or {}


def trim(series, depth):
    if len(series) > depth:
        del series[0:len(series) - depth]


def push(key, value):
    series = HISTORY[key]
    series.append(value)
    trim(series, DEPTH)


def slot_of(moment):
    return int(moment // TREND_BUCKET)


def trend_gap(count):
    for _ in range(min(max(count, 0), TREND_DEPTH)):
        for key in SERIES:
            TREND[key].append(None)


def trend_push(moment):
    slot = slot_of(moment)
    previous = TREND_SLOT["value"]
    if previous is None:
        TREND_SLOT["value"] = slot
        return False
    if slot <= previous:
        return False
    for key in SERIES:
        values = [value for value in PENDING[key] if value is not None]
        TREND[key].append(
            round(sum(values) / len(values), 4) if values else None
        )
        PENDING[key].clear()
    trend_gap(slot - previous - 1)
    for key in SERIES:
        trim(TREND[key], TREND_DEPTH)
    TREND_SLOT["value"] = slot
    return True


def trend_payload():
    payload = {"bucket": TREND_BUCKET, "slot": TREND_SLOT["value"]}
    for key in SERIES:
        payload[key] = list(TREND[key])
    return payload


def trend_save(payload):
    if not TREND_PATH:
        return
    temporary = f"{TREND_PATH}.new"
    try:
        with open(temporary, "w") as handle:
            json.dump(payload, handle)
        os.replace(temporary, TREND_PATH)
    except OSError as error:
        print(f"trend save failed: {error}", flush=True)


def trend_load():
    if not TREND_PATH:
        return
    try:
        with open(TREND_PATH) as handle:
            payload = json.load(handle)
    except FileNotFoundError:
        return
    except (OSError, ValueError) as error:
        print(f"trend load failed: {error}", flush=True)
        return
    if payload.get("bucket") != TREND_BUCKET:
        return
    slot = payload.get("slot")
    if not isinstance(slot, int):
        return
    for key in SERIES:
        values = payload.get(key)
        if not isinstance(values, list):
            continue
        TREND[key] = [
            value if isinstance(value, (int, float)) else None
            for value in values[-TREND_DEPTH:]
        ]
    width = max(len(TREND[key]) for key in SERIES)
    for key in SERIES:
        TREND[key] = [None] * (width - len(TREND[key])) + TREND[key]
    TREND_SLOT["value"] = slot


def trend_resume(moment):
    previous = TREND_SLOT["value"]
    if previous is None:
        return
    slot = slot_of(moment)
    trend_gap(slot - previous)
    for key in SERIES:
        trim(TREND[key], TREND_DEPTH)
    TREND_SLOT["value"] = slot


def sample():
    usage = cpu_usage()
    memory = meminfo()
    temperature = hwmon_temp()
    cards = gpus()
    busy = [card["usage"] for card in cards if card["usage"] is not None]
    values = {
        "cpu_usage": usage,
        "mem_used": memory["used"],
        "cpu_temp_c": temperature,
        "gpu_usage": round(sum(busy) / len(busy), 4) if busy else None,
    }
    payload = None
    with LOCK:
        for key in SERIES:
            push(key, values[key])
            PENDING[key].append(values[key])
        if trend_push(time.time()):
            payload = trend_payload()
    if payload is not None:
        trend_save(payload)


def uptime():
    return round(float(read("/proc/uptime").split()[0]), 1)


def snapshot():
    memory = meminfo()
    load = loadavg()
    disks, errors = smart()
    cards = gpus()
    with LOCK:
        history = {
            "interval": INTERVAL,
            "cpu_usage": list(HISTORY["cpu_usage"]),
            "mem_used": list(HISTORY["mem_used"]),
            "cpu_temp_c": list(HISTORY["cpu_temp_c"]),
        }
        if any(value is not None for value in HISTORY["gpu_usage"]):
            history["gpu_usage"] = list(HISTORY["gpu_usage"])
        recent = HISTORY["cpu_usage"][-1] if HISTORY["cpu_usage"] else None
        span = len(TREND["cpu_usage"])
        slot = TREND_SLOT["value"] or 0
        trend = {
            "bucket": TREND_BUCKET,
            "start": (slot - span) * TREND_BUCKET,
        }
        for key in SERIES:
            if key == "gpu_usage" and not any(
                value is not None for value in TREND[key]
            ):
                continue
            trend[key] = list(TREND[key])

    return {
        "host": HOST,
        "at": int(time.time()),
        "uptime": uptime(),
        "cpu": {
            "cores": os.cpu_count(),
            "load1": load[0],
            "load5": load[1],
            "load15": load[2],
            "usage": recent,
            "temp_c": hwmon_temp(),
        },
        "memory": memory,
        "filesystems": filesystems(),
        "disks": disks,
        "gpus": cards,
        "history": history,
        "trend": trend,
        "errors": errors,
    }


def authorised(header):
    if not TOKEN:
        return True
    if not header or not header.startswith("Bearer "):
        return False
    return hmac.compare_digest(header[7:].strip(), TOKEN)


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    server_version = "stat-agent"
    sys_version = ""

    def respond(self, code, body, content="application/json"):
        self.send_response(code)
        self.send_header("Content-Type", content)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        path = self.path.split("?")[0]

        if path == "/healthz":
            self.respond(200, b"ok\n", "text/plain; charset=utf-8")
            return

        if path != "/stats":
            self.respond(404, b"not found\n", "text/plain; charset=utf-8")
            return

        if not authorised(self.headers.get("Authorization")):
            self.respond(401, b"unauthorized\n", "text/plain; charset=utf-8")
            return

        try:
            body = json.dumps(snapshot()).encode()
        except Exception as error:
            print(f"snapshot failed: {error}", flush=True)
            self.respond(500, b"snapshot failed\n", "text/plain; charset=utf-8")
            return

        self.respond(200, body)

    def log_message(self, fmt, *args):
        return


def collect():
    while True:
        try:
            sample()
        except Exception as error:
            print(f"sample failed: {error}", flush=True)
        time.sleep(INTERVAL)


cpu_times()
trend_load()
trend_resume(time.time())
threading.Thread(target=collect, daemon=True).start()
print(f"stat-agent on {BIND}:{PORT}", flush=True)
ThreadingHTTPServer((BIND, PORT), Handler).serve_forever()
