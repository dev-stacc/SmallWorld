#!/usr/bin/env python3
import os
import json
import sys
import urllib.request
import urllib.error

PRIMARY_URL = os.environ["PRIMARY_URL"].rstrip("/")
PRIMARY_PASSWORD = os.environ["PRIMARY_PASSWORD"]
SECONDARY_URL = os.environ["SECONDARY_URL"].rstrip("/")
SECONDARY_PASSWORD = os.environ["SECONDARY_PASSWORD"]

def auth(base_url, password):
    payload = json.dumps({"password": password}).encode()
    req = urllib.request.Request(
        f"{base_url}/api/auth",
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read())["session"]["sid"]

def api(base_url, sid, method, path, body=None):
    payload = json.dumps(body).encode() if body else None
    req = urllib.request.Request(
        f"{base_url}{path}",
        data=payload,
        headers={"Content-Type": "application/json", "Cookie": f"sid={sid}"},
        method=method,
    )
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read()) if resp.length != 0 else None
    except urllib.error.HTTPError as e:
        if e.code == 204:
            return None
        raise

def sync_domains(p_url, p_sid, s_url, s_sid, dtype, dkind):
    p_all = api(p_url, p_sid, "GET", f"/api/domains/{dtype}/{dkind}")
    s_all = api(s_url, s_sid, "GET", f"/api/domains/{dtype}/{dkind}")

    p_domains = {d["domain"]: d for d in p_all.get("domains", [])
                 if d.get("comment", "") != "crowdsec"}
    s_domains = {d["domain"]: d for d in s_all.get("domains", [])
                 if d.get("comment", "") != "crowdsec"}

    for domain in set(p_domains) - set(s_domains):
        d = p_domains[domain]
        api(s_url, s_sid, "POST", f"/api/domains/{dtype}/{dkind}",
            {"domain": domain, "comment": d.get("comment", ""), "enabled": d.get("enabled", True)})
        print(f"+ {dtype}/{dkind}: {domain}", flush=True)

    for domain in set(s_domains) - set(p_domains):
        try:
            api(s_url, s_sid, "DELETE", f"/api/domains/{dtype}/{dkind}/{domain}")
            print(f"- {dtype}/{dkind}: {domain}", flush=True)
        except urllib.error.HTTPError as e:
            if e.code != 404:
                raise

def sync_lists(p_url, p_sid, s_url, s_sid, list_type):
    p_lists = {l["address"]: l for l in api(p_url, p_sid, "GET", f"/api/lists?type={list_type}").get("lists", [])}
    s_lists = {l["address"]: l for l in api(s_url, s_sid, "GET", f"/api/lists?type={list_type}").get("lists", [])}

    for address in set(p_lists) - set(s_lists):
        l = p_lists[address]
        api(s_url, s_sid, "POST", "/api/lists",
            {"address": address, "type": list_type,
             "enabled": l.get("enabled", True), "comment": l.get("comment", "")})
        print(f"+ {list_type}list: {address}", flush=True)

    for address in set(s_lists) - set(p_lists):
        lid = s_lists[address]["id"]
        try:
            api(s_url, s_sid, "DELETE", f"/api/lists/{lid}")
            print(f"- {list_type}list: {address}", flush=True)
        except urllib.error.HTTPError as e:
            if e.code != 404:
                raise

def logout(base_url, sid):
    if not sid:
        return
    try:
        api(base_url, sid, "DELETE", "/api/auth")
    except Exception as e:
        print(f"logout warning ({base_url}): {e}", flush=True)

print(f"syncing {PRIMARY_URL} -> {SECONDARY_URL}", flush=True)
p_sid = None
s_sid = None
try:
    try:
        p_sid = auth(PRIMARY_URL, PRIMARY_PASSWORD)
        s_sid = auth(SECONDARY_URL, SECONDARY_PASSWORD)
    except Exception as e:
        print(f"auth failed: {e}", flush=True)
        sys.exit(1)

    for dtype in ("allow", "deny"):
        for dkind in ("exact", "regex"):
            sync_domains(PRIMARY_URL, p_sid, SECONDARY_URL, s_sid, dtype, dkind)

    for list_type in ("block", "allow"):
        sync_lists(PRIMARY_URL, p_sid, SECONDARY_URL, s_sid, list_type)

    print("done", flush=True)
finally:
    logout(PRIMARY_URL, p_sid)
    logout(SECONDARY_URL, s_sid)
