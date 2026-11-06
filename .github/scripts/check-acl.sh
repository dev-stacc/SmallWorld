#!/usr/bin/env bash
set -uo pipefail

cd "$(git rev-parse --show-toplevel)"

policy="${1:?usage: check-acl.sh <policy.hujson>}"

RESOLVER_HOST="aperture"
DNS_PORTS=("udp:53" "tcp:53")

blocked=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

report() {
    printf '  %s\n' "$*" >&2
    blocked=1
}

json="$tmp/policy.json"

hujson_to_json() {
    python3 - "$policy" > "$json" <<'PY'
import json, re, sys

src = open(sys.argv[1], encoding="utf-8").read()
out, i, n = [], 0, len(src)

while i < n:
    c = src[i]
    if c == '"':
        j = i + 1
        while j < n:
            if src[j] == "\\":
                j += 2
                continue
            if src[j] == '"':
                break
            j += 1
        out.append(src[i:j + 1])
        i = j + 1
        continue
    if src.startswith("//", i):
        while i < n and src[i] != "\n":
            i += 1
        continue
    if src.startswith("/*", i):
        i = src.find("*/", i)
        i = n if i < 0 else i + 2
        continue
    out.append(c)
    i += 1

stripped = re.sub(r",(\s*[}\]])", r"\1", "".join(out))

try:
    json.dump(json.loads(stripped), sys.stdout)
except json.JSONDecodeError as e:
    print(f"line {e.lineno} column {e.colno}: {e.msg}", file=sys.stderr)
    raise SystemExit(1)
PY
}

check_parses() {
    hujson_to_json 2>"$tmp/err" && return 0
    report "policy does not parse as HuJSON: $(tail -1 "$tmp/err")"
    return 1
}

check_dns_reaches_every_identity() {
    local identities id missing
    identities=$(jq -r '(.tagOwners | keys[]), "autogroup:member"' "$json")

    while IFS= read -r id; do
        missing=$(jq -r --arg id "$id" --arg dst "$RESOLVER_HOST" \
            --arg udp "${DNS_PORTS[0]}" --arg tcp "${DNS_PORTS[1]}" '
            [ .grants[]
              | select((.src // []) | index($id))
              | select((.dst // []) | index($dst))
              | select(((.ip // []) | index($udp)) and ((.ip // []) | index($tcp)))
            ] | length' "$json")

        [ "$missing" != "0" ] || report "no :53 grant from $id to $RESOLVER_HOST"
    done <<< "$identities"
}

check_every_identity_is_tested() {
    local id tested
    while IFS= read -r id; do
        tested=$(jq -r --arg id "$id" --arg probe "$RESOLVER_HOST:53" '
            [ .tests[] | select(.src == $id) | select((.accept // []) | index($probe)) ]
            | length' "$json")

        [ "$tested" != "0" ] || report "no test asserting $id can reach $RESOLVER_HOST:53"
    done < <(jq -r '.tagOwners | keys[]' "$json")
}

check_hosts_match_flake() {
    local name want got
    nix eval --json .#tailnet.ips > "$tmp/ips.json" 2>"$tmp/niderr" || {
        report "could not read tailnet.ips from flake.nix: $(tail -1 "$tmp/niderr")"
        return 1
    }

    while IFS= read -r name; do
        want=$(jq -r --arg n "$name" '.[$n] // empty' "$tmp/ips.json")
        got=$(jq -r --arg n "$name" '.hosts[$n]' "$json")

        [ -n "$want" ] || continue
        [ "$want" != "PLACEHOLDER" ] || continue
        [ "$want" = "$got" ] || report "host $name is $got in policy but $want in flake.nix"
    done < <(jq -r '.hosts | keys[]' "$json")
}

check_parses || exit 1
check_dns_reaches_every_identity
check_every_identity_is_tested
check_hosts_match_flake

if [ "$blocked" -ne 0 ]; then
    printf 'tailnet policy rejected\n' >&2
    exit 1
fi

printf 'acl ok: %s identities have DNS, %s hosts match flake.nix\n' \
    "$(jq -r '(.tagOwners | length) + 1' "$json")" \
    "$(jq -r '.hosts | length' "$json")"
