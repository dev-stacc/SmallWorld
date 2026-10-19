#!/usr/bin/env bash
set -euo pipefail

case "${1-}" in
    agent | chat)
        exec @agent@ "$@"
        ;;
esac

url=${OSS_URL:-http://altair:8080/v1}
key_file=${OSS_KEY_FILE:-/run/secrets/llama-api-key}
max_tokens=2048
effort=low
raw=0
wait_slot=0

usage() {
    cat <<'USAGE'
oss [-m MAX_TOKENS] [-e low|medium|high] [--json] [--wait] PROMPT
oss agent [--text] [--max-turns N] TASK
oss chat

Stdin is appended to PROMPT as context when it is not a terminal.
USAGE
}

while [ $# -gt 0 ]; do
    case "$1" in
        -m)
            max_tokens=$2
            shift 2
            ;;
        -e)
            effort=$2
            shift 2
            ;;
        --json)
            raw=1
            shift
            ;;
        --wait)
            wait_slot=1
            shift
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -*)
            printf 'unknown option: %s\n' "$1" >&2
            exit 2
            ;;
        *)
            break
            ;;
    esac
done

if [ $# -eq 0 ] && [ -t 0 ]; then
    usage >&2
    exit 2
fi

if [ ! -r "$key_file" ]; then
    printf 'cannot read %s\n' "$key_file" >&2
    exit 1
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

: > "$tmp/ctx"
if [ ! -t 0 ]; then
    cat > "$tmp/ctx"
fi

jq -n \
    --arg p "$*" \
    --rawfile c "$tmp/ctx" \
    --argjson m "$max_tokens" \
    --arg e "$effort" \
    '{
        model: "gpt-oss-20b",
        max_tokens: $m,
        chat_template_kwargs: { reasoning_effort: $e },
        messages: [{
            role: "user",
            content: (if ($c | length) > 0 then ($p + "\n\n" + $c) else $p end)
        }]
    }' > "$tmp/payload"

lock=${XDG_RUNTIME_DIR:-/tmp}/oss.lock
exec 9>>"$lock"
if [ "$wait_slot" = 1 ]; then
    flock 9
elif ! flock -n 9; then
    printf 'the single inference slot is busy: %s\n' "$(cat "$lock")" >&2
    exit 1
fi
printf 'pid %s since %s\n' "$$" "$(date +%s)" > "$lock"

delay=2
code=000
for attempt in 1 2 3; do
    code=$(curl -sS \
        --config <(printf 'header = "Authorization: Bearer %s"\n' "$(cat "$key_file")") \
        -H 'Content-Type: application/json' \
        --data-binary "@$tmp/payload" \
        --max-time 600 \
        -o "$tmp/body" \
        -w '%{http_code}' \
        "$url/chat/completions") || code=000

    case "$code" in
        200) break ;;
        000 | 5*)
            if [ "$attempt" = 3 ]; then break; fi
            sleep "$delay"
            delay=$((delay * 3))
            ;;
        *) break ;;
    esac
done

if [ "$code" != 200 ]; then
    if [ -s "$tmp/body" ]; then
        jq -r '.error.message // "request failed"' "$tmp/body" >&2 2>/dev/null \
            || cat "$tmp/body" >&2
    else
        printf 'no response from %s (http %s)\n' "$url" "$code" >&2
    fi
    exit 1
fi

if [ "$raw" = 1 ]; then
    cat "$tmp/body"
else
    jq -r '.choices[0].message.content // ""' "$tmp/body"
fi
