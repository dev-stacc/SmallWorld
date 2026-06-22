#!/usr/bin/env python3
import os
import json
import time
import urllib.request
import urllib.error

LAPI_URL = os.environ["LAPI_URL"].rstrip("/")
BOUNCER_API_KEY = os.environ["BOUNCER_API_KEY"]
PIHOLE_URL = os.environ["PIHOLE_URL"].rstrip("/")
PIHOLE_PASSWORD = os.environ["PIHOLE_PASSWORD"]

sid = None

def logout(old_sid):
    if not old_sid:
        return
    try:
        req = urllib.request.Request(
            f"{PIHOLE_URL}/api/auth",
            headers={"Cookie": f"sid={old_sid}"},
            method="DELETE",
        )
        urllib.request.urlopen(req)
    except Exception:
        pass

def auth():
    global sid
    logout(sid)
    payload = json.dumps({"password": PIHOLE_PASSWORD}).encode()
    req = urllib.request.Request(
        f"{PIHOLE_URL}/api/auth",
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read())
        sid = data["session"]["sid"]

def pihole_req(method, path, body=None):
    payload = json.dumps(body).encode() if body else None
    req = urllib.request.Request(
        f"{PIHOLE_URL}{path}",
        data=payload,
        headers={"Content-Type": "application/json", "Cookie": f"sid={sid}"},
        method=method,
    )
    return urllib.request.urlopen(req)

def add(ip):
    try:
        pihole_req("POST", "/api/domains/deny/exact", {"domain": ip, "comment": "crowdsec"})
        print(f"blocked {ip}", flush=True)
    except urllib.error.HTTPError as e:
        if e.code != 409:
            raise

def remove(ip):
    try:
        pihole_req("DELETE", f"/api/domains/deny/exact/{ip}")
        print(f"unblocked {ip}", flush=True)
    except urllib.error.HTTPError as e:
        if e.code != 404:
            raise

def get_decisions(startup=False):
    url = f"{LAPI_URL}/v1/decisions/stream"
    if startup:
        url += "?startup=true"
    req = urllib.request.Request(url, headers={"X-Api-Key": BOUNCER_API_KEY})
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read())

def sync(startup=False):
    data = get_decisions(startup=startup)
    for d in data.get("new") or []:
        add(d["value"])
    for d in data.get("deleted") or []:
        remove(d["value"])

while True:
    try:
        auth()
        sync(startup=True)
        print("bouncer started", flush=True)
        break
    except Exception as e:
        print(f"startup failed: {e}, retrying in 10s", flush=True)
        time.sleep(10)

while True:
    time.sleep(30)
    try:
        sync()
    except urllib.error.HTTPError as e:
        if e.code in (401, 403):
            print("re-authenticating", flush=True)
            try:
                auth()
            except Exception as ae:
                print(f"re-auth failed: {ae}", flush=True)
        else:
            print(f"sync error: {e}", flush=True)
    except Exception as e:
        print(f"sync error: {e}", flush=True)
