#!/usr/bin/env bash
set -euo pipefail

url=${PIHOLE_URL:?}
rules=${PIHOLE_RULES:?}
marker=${PIHOLE_MARKER:?}
password=${FTLCONF_webserver_api_password:?}

body=$(mktemp)
sid=""

cleanup() {
    if [ -n "$sid" ]; then
        curl -sS -m 10 -o /dev/null -X DELETE -H "X-FTL-SID: $sid" "$url/api/auth" || true
    fi
    rm -f "$body"
}
trap cleanup EXIT

for _ in $(seq 1 30); do
    sid=$(jq -cn --arg p "$password" '{password: $p}' \
        | curl -sS -m 10 -H 'Content-Type: application/json' --data @- "$url/api/auth" \
        | jq -r '.session.sid // empty') || sid=""
    if [ -n "$sid" ]; then
        break
    fi
    sleep 5
done

if [ -z "$sid" ]; then
    echo "pihole-seed: auth failed against $url" >&2
    exit 1
fi

send() {
    local method=$1 path=$2 accept=$3 data=${4:-}
    local attempt code
    for attempt in 1 2 3; do
        if [ -n "$data" ]; then
            code=$(printf '%s' "$data" \
                | curl -sS -m 20 -o "$body" -w '%{http_code}' -X "$method" \
                    -H "X-FTL-SID: $sid" -H 'Content-Type: application/json' --data @- \
                    "$url$path")
        else
            code=$(curl -sS -m 20 -o "$body" -w '%{http_code}' -X "$method" \
                -H "X-FTL-SID: $sid" "$url$path")
        fi
        case " $accept " in
            *" $code "*)
                return 0
                ;;
        esac
        sleep 2
    done
    echo "pihole-seed: $method $code $path -- $(head -c 200 "$body")" >&2
    return 1
}

current=$(curl -sS -m 20 -H "X-FTL-SID: $sid" "$url/api/domains")

plan=$(jq -r --argjson cur "$current" --arg m "$marker" '
    . as $r
    | ($cur.domains // []) as $have
    | [ ("deny", "allow") as $t
        | ("exact", "regex") as $k
        | (($r[$t] // {})[$k] // [])[]
        | { type: $t, kind: $k, domain: . } ] as $want
    | ( $want[]
        | . as $w
        | ( [ $have[]
              | select(.type == $w.type and .kind == $w.kind and .domain == $w.domain) ]
            | first ) as $e
        | select($e == null or $e.comment != $m or $e.enabled != true)
        | [ "PUT", $w.type, $w.kind, $w.domain, ($w.domain | @uri) ] | join("\t") ),
      ( $have[]
        | . as $e
        | select(.comment == $m)
        | select( [ $want[]
                    | select(.type == $e.type and .kind == $e.kind and .domain == $e.domain) ]
                  | length == 0 )
        | [ "DEL", $e.type, $e.kind, $e.domain, ($e.domain | @uri) ] | join("\t") )
' "$rules")

payload=$(jq -cn --arg c "$marker" '{comment: $c, enabled: true, groups: [0]}')
written=0
removed=0
failed=0

while IFS=$'\t' read -r action dtype dkind domain escaped; do
    if [ -z "${action:-}" ]; then
        continue
    fi
    case $action in
        PUT)
            if send PUT "/api/domains/$dtype/$dkind/$escaped" "200 201" "$payload"; then
                written=$((written + 1))
            else
                failed=$((failed + 1))
                echo "pihole-seed: failed to write $dtype/$dkind $domain" >&2
            fi
            ;;
        DEL)
            if send DELETE "/api/domains/$dtype/$dkind/$escaped" "200 204 404"; then
                removed=$((removed + 1))
            else
                failed=$((failed + 1))
                echo "pihole-seed: failed to remove $dtype/$dkind $domain" >&2
            fi
            ;;
    esac
done <<< "$plan"

declared=$(jq -r '[ .deny.regex, .deny.exact, .allow.regex, .allow.exact ]
    | map(length // 0) | add' "$rules")

echo "pihole-seed: $declared declared, $written written, $removed removed, $failed failed"
[ "$failed" -eq 0 ]
