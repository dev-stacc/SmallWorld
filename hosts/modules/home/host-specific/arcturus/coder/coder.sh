#!/usr/bin/env bash
set -euo pipefail

url=${CODER_URL:-http://altair:8080}
key_file=${CODER_KEY_FILE:-/run/secrets/llama-api-key}
model=${CODER_MODEL:-qwen3-coder}

bg=${CODER_BG:-@base00@}
dim=${CODER_DIM:-@base07@}
error=${CODER_ERROR:-@base02@}
input=${CODER_INPUT:-@base03@}
warn=${CODER_WARN:-@base04@}
output=${CODER_OUTPUT:-@base05@}
tool=${CODER_TOOL:-@base06@}
code_theme=${CODER_CODE_THEME:-@codeTheme@}

paint() {
    printf '\033[38;2;%d;%d;%dm%s\033[0m\n' \
        "$((16#${1:0:2}))" "$((16#${1:2:2}))" "$((16#${1:4:2}))" "$2"
}

usage() {
    cat <<'USAGE'
coder [AIDER_ARGS...] [FILE...]

An aider session against Altair. Starts in ask mode, so it answers without
touching files; /code switches it to editing, /ask switches back. Defaults to
qwen3-coder; override with CODER_MODEL. Holds the single inference slot for the
whole session, so oss one-shots will report it as busy. Switching models costs
about three minutes.

In the session: /add FILE to put a file in context, /drop to remove it,
/diff to review, /undo to revert the last edit.

Colors come from the theme and are overridable: CODER_BG, CODER_DIM,
CODER_ERROR, CODER_INPUT, CODER_WARN, CODER_OUTPUT, CODER_TOOL as bare hex,
CODER_CODE_THEME as a pygments style name.
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

loaded=$(curl -sS --max-time 10 --config <(printf '%s\n' "$auth") "$url/running" \
    | jq -r '.running[]? | select(.state == "ready") | .model' 2>/dev/null) || loaded=""

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

paint "$dim" "$model on $url, ask mode; /code to let it edit"

OPENAI_API_KEY=$(cat "$key_file")
export OPENAI_API_KEY

exec aider \
    --model "openai/$model" \
    --openai-api-base "$url/v1" \
    --model-metadata-file @metadata@ \
    --model-settings-file @settings@ \
    --chat-mode ask \
    --map-tokens 512 \
    --cache-prompts \
    --no-auto-commits \
    --no-gitignore \
    --no-show-model-warnings \
    --no-show-release-notes \
    --no-check-update \
    --no-analytics \
    --code-theme "$code_theme" \
    --user-input-color "#$input" \
    --assistant-output-color "#$output" \
    --tool-output-color "#$tool" \
    --tool-warning-color "#$warn" \
    --tool-error-color "#$error" \
    --completion-menu-color "#$output" \
    --completion-menu-bg-color "#$bg" \
    --completion-menu-current-color "#$bg" \
    --completion-menu-current-bg-color "#$error" \
    "$@"
