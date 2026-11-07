import json
import os
import subprocess
import sys

OUT = os.environ["SMART_OUT"]


def run(*args):
    result = subprocess.run(
        ["smartctl", "-j", *args], capture_output=True, text=True, timeout=60
    )
    if not result.stdout:
        raise RuntimeError(result.stderr.strip()[:200] or "no output")
    return json.loads(result.stdout)


def by_id(device):
    root = "/dev/disk/by-id"
    try:
        names = os.listdir(root)
    except OSError:
        return os.path.basename(device)
    best = None
    for name in names:
        if name.startswith("wwn-") or "-part" in name:
            continue
        if os.path.realpath(os.path.join(root, name)) == os.path.realpath(device):
            if best is None or len(name) < len(best):
                best = name
    return best or os.path.basename(device)


def attribute(payload, wanted):
    table = (payload.get("ata_smart_attributes") or {}).get("table") or []
    for entry in table:
        if entry.get("name") == wanted:
            return (entry.get("raw") or {}).get("value")
    return None


def written(payload):
    nvme = payload.get("nvme_smart_health_information_log") or {}
    units = nvme.get("data_units_written")
    if isinstance(units, int):
        return units * 512 * 1000
    return None


def describe(device):
    payload = run("-A", "-H", "-i", device)
    status = payload.get("smart_status") or {}
    temperature = (payload.get("temperature") or {}).get("current")
    return {
        "name": by_id(device),
        "device": device,
        "model": payload.get("model_name") or "",
        "temp_c": temperature,
        "health": "PASSED" if status.get("passed") else "FAILED" if status else "",
        "power_on_hours": (payload.get("power_on_time") or {}).get("hours"),
        "written_bytes": written(payload),
        "lbas_written": attribute(payload, "Total_LBAs_Written"),
    }


def main():
    disks = []
    errors = {}

    try:
        scan = run("--scan-open").get("devices") or []
    except Exception as error:
        scan = []
        errors["scan"] = str(error)[:200]

    for entry in scan:
        device = entry.get("name")
        if not device:
            continue
        try:
            disks.append(describe(device))
        except Exception as error:
            errors[device] = str(error)[:200]

    disks.sort(key=lambda item: item["name"])

    tmp = OUT + ".tmp"
    with open(tmp, "w") as handle:
        json.dump({"disks": disks, "errors": errors}, handle)
    os.replace(tmp, OUT)
    os.chmod(OUT, 0o644)

    if errors and not disks:
        print(json.dumps(errors), file=sys.stderr)
        return 1
    return 0


sys.exit(main())
