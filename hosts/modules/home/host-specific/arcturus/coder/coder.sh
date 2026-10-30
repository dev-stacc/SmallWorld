#!/usr/bin/env bash
set -euo pipefail

url=${CODER_URL:-http://altair:8080}
key_file=${CODER_KEY_FILE:-/run/secrets/llama-api-key}
model=${CODER_MODEL:-qwen3-coder}

usage() {
    cat <<'USAGE'
coder [AIDER_ARGS...] [FILE...]

An aider session against Altair. Defaults to qwen3-coder; override with
CODER_MODEL. Holds the single inference slot for the whole session, so oss
one-shots will report it as busy. Switching models costs about three minutes.

In the session: /add FILE to put a file in context, /drop to remove it,
/ask to ask without editing, /diff to review, /undo to revert the last edit.
USAGE
}

if [ "${1-}" = "-h" ] || [ "${1-}" = "--help" ]; then
    usage
    exit 0
fi

if [ ! -r "$key_file" ]; then
    printf 'cannot read %s\n' "$key_file" >&2
    exit 1
fi

auth=$(printf 'header = "Authorization: Bearer %s"\n' "$(cat "$key_file")")

loaded=$(curl -sS --max-time 10 --config <(printf '%s\n' "$auth") "$url/running" \
    | jq -r '.running[]? | select(.state == "ready") | .model' 2>/dev/null) || loaded=""

if [ -z "$loaded" ]; then
    printf 'warning: altair reports nothing loaded; the first prompt will block\n' >&2
elif [ "$loaded" != "$model" ]; then
    printf 'warning: altair has %s loaded, not %s; the first prompt costs a swap\n' \
        "$loaded" "$model" >&2
fi

lock=${XDG_RUNTIME_DIR:-/tmp}/oss.lock
exec 9>>"$lock"
if ! flock -n 9; then
    printf 'the single inference slot is busy: %s\n' "$(cat "$lock")" >&2
    exit 1
fi
printf 'pid %s since %s\n' "$$" "$(date +%s)" > "$lock"

OPENAI_API_KEY=$(cat "$key_file")
export OPENAI_API_KEY

exec aider \
    --model "openai/$model" \
    --openai-api-base "$url/v1" \
    --model-metadata-file @metadata@ \
    --edit-format diff \
    --map-tokens 512 \
    --cache-prompts \
    --no-auto-commits \
    --no-gitignore \
    --no-show-model-warnings \
    --no-show-release-notes \
    --no-check-update \
    --no-analytics \
    "$@"
