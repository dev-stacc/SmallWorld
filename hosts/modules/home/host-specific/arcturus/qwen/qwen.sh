#!/usr/bin/env bash
set -euo pipefail

url=${QWEN_URL:-http://altair:8080}
key_file=${QWEN_KEY_FILE:-/run/secrets/llama-api-key}
model=${QWEN_MODEL:-qwen3-coder}

dim=${QWEN_DIM:-@dim@}
warn=${QWEN_WARN:-@warn@}
error=${QWEN_ERROR:-@error@}

paint() {
    printf '\033[38;2;%d;%d;%dm%s\033[0m\n' \
        "$((16#${1:0:2}))" "$((16#${1:2:2}))" "$((16#${1:4:2}))" "$2"
}

usage() {
    cat <<'USAGE'
qwen [QWEN_CODE_ARGS...]

qwen-code against Altair, themed and permission-fenced. Defaults to
qwen3-coder; override with QWEN_MODEL. Holds the single inference slot for the
whole session, so oss one-shots will report it as busy. Switching models costs
about three minutes.

Read-only diagnostics run unprompted: kubectl get/describe/logs/top, flux get,
journalctl, systemctl status, git log/diff, and the usual file readers.
Everything that writes asks first. Secrets, sudo, sops, rm, deploys and
"oss"/"coder" (they would deadlock on the inference slot) are refused outright.

  --approval-mode plan      read-only planning, no tool writes at all
  --approval-mode default   ask before each write (the default)
  --approval-mode yolo      approve everything; the deny list still applies
  -p PROMPT                 one-shot, non-interactive

Settings come from the Nix store; your own ~/.local/state/qwen/settings.json
still wins, and permission rules you persist are unioned with the built-in
ones. QWEN_HOME points at ~/.local/state/qwen.
USAGE
}

if [ "${1-}" = "-h" ] || [ "${1-}" = "--help" ]; then
    usage
    exit 0
fi

if [ ! -r "$key_file" ]; then
    paint "$error" "cannot read $key_file" >&2
    exit 1
fi

auth=$(printf 'header = "Authorization: Bearer %s"\n' "$(cat "$key_file")")

loaded=$(curl -s --max-time 10 --config <(printf '%s\n' "$auth") "$url/running" \
    | jq -r '.running[]? | select(.state == "ready") | .model') || loaded=""

if [ -z "$loaded" ]; then
    paint "$warn" "altair reports nothing loaded; the first prompt will block" >&2
elif [ "$loaded" != "$model" ]; then
    paint "$warn" "altair has $loaded loaded, not $model; the first prompt costs a swap" >&2
fi

lock=${XDG_RUNTIME_DIR:-/tmp}/oss.lock
exec 9>>"$lock"
if ! flock -n 9; then
    paint "$error" "the single inference slot is busy: $(cat "$lock")" >&2
    exit 1
fi
printf 'pid %s since %s\n' "$$" "$(date +%s)" > "$lock"

QWEN_HOME=${QWEN_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}/qwen}
mkdir -p "$QWEN_HOME"
export QWEN_HOME

export QWEN_CODE_SYSTEM_DEFAULTS_PATH=@settings@
export QWEN_SYSTEM_MD=@system@
export OPENAI_BASE_URL="$url/v1"
export OPENAI_MODEL="$model"
OPENAI_API_KEY=$(cat "$key_file")
export OPENAI_API_KEY

paint "$dim" "$model on $url, ask mode; /approval-mode to change"

exec @qwen@ "$@"
