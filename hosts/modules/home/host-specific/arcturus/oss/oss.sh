#!/usr/bin/env bash
set -euo pipefail

case "${1-}" in
    agent | chat)
        exec @agent@ "$@"
        ;;
esac

url=${OSS_URL:-http://altair:8080/v1}
key_file=${OSS_KEY_FILE:-/run/secrets/llama-api-key}
model=${OSS_MODEL:-gpt-oss-20b-uncensored}
max_tokens=2048
effort=low
raw=0
wait_slot=1
stream=1
think=auto
strict=0
temp=
seed=

usage() {
    cat <<'USAGE'
oss [-M MODEL] [-m MAX_TOKENS] [-e low|medium|high] [OPTIONS] PROMPT
oss agent [--model MODEL] [--text] [--max-turns N] TASK
oss chat [--model MODEL] [--resume]
oss models | running | runs | show N

  -M, --model MODEL  model name or alias: @aliasNames@
  -m MAX_TOKENS      output cap, default 2048
  -e EFFORT          reasoning effort: low, medium, high
  --temp T           sampling temperature; unset means the model default
  --seed N           fixed seed, for reproducible output
  --no-stream        wait for the whole response instead of streaming it
  --json             print the raw response object, implies --no-stream
  --think            show reasoning and load progress on stderr
  --no-think         hide them; default is --think while streaming
  --strict           exit 3 when the answer was truncated
  --no-wait          fail instead of queueing for the inference slot

Stdin is appended to PROMPT as context when it is not a terminal. Only the
answer goes to stdout, so pipes stay clean; reasoning, load progress and
warnings go to stderr. Truncation always warns.

"oss runs" lists agent transcripts newest first, "oss show N" replays one.
Altair serves one model at a time; asking for one that is not loaded costs
about two minutes. Check with "oss running".
USAGE
}

while [ $# -gt 0 ]; do
    case "$1" in
        -M | --model)
            model=$2
            shift 2
            ;;
        -m)
            max_tokens=$2
            shift 2
            ;;
        -e)
            effort=$2
            shift 2
            ;;
        --temp)
            temp=$2
            shift 2
            ;;
        --seed)
            seed=$2
            shift 2
            ;;
        --json)
            raw=1
            shift
            ;;
        --stream)
            stream=1
            shift
            ;;
        --no-stream)
            stream=0
            shift
            ;;
        --think)
            think=1
            shift
            ;;
        --no-think)
            think=0
            shift
            ;;
        --strict)
            strict=1
            shift
            ;;
        --wait)
            wait_slot=1
            shift
            ;;
        --no-wait)
            wait_slot=0
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

if [ "$raw" = 1 ]; then
    stream=0
fi

if [ "$think" = auto ]; then
    think=$stream
fi

case "$max_tokens" in
    '' | *[!0-9]*)
        printf 'invalid -m: %s\n' "$max_tokens" >&2
        exit 2
        ;;
esac

case "$effort" in
    low | medium | high) ;;
    *)
        printf 'invalid -e: %s\n' "$effort" >&2
        exit 2
        ;;
esac

if [ -n "$temp" ]; then
    case "$temp" in
        *[!0-9.]* | '' | *.*.*)
            printf 'invalid --temp: %s\n' "$temp" >&2
            exit 2
            ;;
    esac
fi

if [ -n "$seed" ]; then
    case "${seed#-}" in
        '' | *[!0-9]*)
            printf 'invalid --seed: %s\n' "$seed" >&2
            exit 2
            ;;
    esac
fi

resolve_model() {
    case $model in
        @aliasArms@
    esac
}

resolve_model

if [ $# -eq 0 ] && [ -t 0 ]; then
    usage >&2
    exit 2
fi

state_dir=${XDG_STATE_HOME:-$HOME/.local/state}/oss

run_files() {
    local f
    shopt -s nullglob
    for f in "$state_dir"/[0-9]*.jsonl; do
        printf '%s\n' "$f"
    done
    shopt -u nullglob
}

list_runs() {
    local files=() i n
    mapfile -t files < <(run_files)
    if [ ${#files[@]} -eq 0 ]; then
        printf 'no agent runs in %s\n' "$state_dir"
        return
    fi
    n=1
    for ((i = ${#files[@]} - 1; i >= 0; i--)); do
        printf '%s\t%s\t%s\n' "$n" \
            "$(date -r "${files[i]}" '+%Y-%m-%d %H:%M')" \
            "$(jq -rs '
                ((map(select(.kind == "task")) | first | .data.task) // "?")
                    as $task
                | ((map(select(.kind == "result")) | last | .data) // {}) as $r
                | [($r.stop_reason // "incomplete"),
                   (($r.turns // 0) | tostring) + " turns",
                   (($r.tokens // 0) | tostring) + " tok",
                   ($task | gsub("\\s+"; " ") | .[0:60])] | join("  ")
            ' "${files[i]}")"
        n=$((n + 1))
    done
}

show_run() {
    local files=() index=$1 target
    mapfile -t files < <(run_files)
    case $index in
        '' | *[!0-9]*)
            printf 'oss show takes a run number from "oss runs"\n' >&2
            return 2
            ;;
    esac
    if [ "$index" -lt 1 ] || [ "$index" -gt ${#files[@]} ]; then
        printf 'no such run: %s\n' "$index" >&2
        return 2
    fi
    target=${files[${#files[@]} - index]}
    printf '%s\n\n' "$target"
    jq -r '
        ((.t // 0) | tostring) as $t
        | if .kind == "task" then "task: " + (.data.task // "?")
          elif .kind == "assistant" then
            $t + "s turn"
            + (if .data.tool_calls then " -> "
                 + ([.data.tool_calls[].function.name] | join(", "))
               else "" end)
            + (if (.data.content // "") == "" then ""
               else "\n" + .data.content end)
          elif .kind == "tool" then
            $t + "s   " + (.data.name // "?") + " "
            + ((.data.args // {}) | tojson) + " -> "
            + (if .data.error then .data.error
               else ((.data.bytes // 0) | tostring) + " bytes" end)
          else $t + "s " + .kind + ": " + (.data | tojson)
          end
    ' "$target"
}

case "${1-}" in
    runs)
        list_runs
        exit 0
        ;;
    show)
        show_run "${2-1}"
        exit $?
        ;;
esac

if [ ! -r "$key_file" ]; then
    printf 'cannot read %s\n' "$key_file" >&2
    exit 1
fi

auth=$(printf 'header = "Authorization: Bearer %s"\n' "$(cat "$key_file")")

case "${1-}" in
    models)
        curl -sS --config <(printf '%s\n' "$auth") "$url/models" \
            | jq -r '.data[] | [.id, (.description // "")] | @tsv'
        exit 0
        ;;
    running)
        curl -sS --config <(printf '%s\n' "$auth") "${url%/v1}/running" \
            | jq -r 'if (.running | length) == 0 then "nothing loaded"
                     else (.running[] | [.model, .state] | @tsv) end'
        exit 0
        ;;
esac

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
    --arg mdl "$model" \
    --argjson s "$stream" \
    --arg t "$temp" \
    --arg sd "$seed" \
    '{
        model: $mdl,
        max_tokens: $m,
        stream: ($s == 1),
        chat_template_kwargs: { reasoning_effort: $e },
        messages: [{
            role: "user",
            content: (if ($c | length) > 0 then ($p + "\n\n" + $c) else $p end)
        }]
    }
    | (if $t == "" then . else .temperature = ($t | tonumber) end)
    | (if $sd == "" then . else .seed = ($sd | tonumber) end)' > "$tmp/payload"

loaded=$(curl -s --max-time 10 --config <(printf '%s\n' "$auth") \
    "${url%/v1}/running" \
    | jq -r '.running[]? | select(.state == "ready") | .model') || loaded=""

if [ -z "$loaded" ]; then
    printf 'altair has nothing ready; loading %s takes about two minutes\n' \
        "$model" >&2
elif [ "$loaded" != "$model" ]; then
    printf 'altair has %s ready, not %s; the swap takes about two minutes\n' \
        "$loaded" "$model" >&2
fi

lock=${XDG_RUNTIME_DIR:-/tmp}/oss.lock
exec 9>>"$lock"
if ! flock -n 9; then
    if [ "$wait_slot" = 0 ]; then
        printf 'the single inference slot is busy: %s\n' "$(cat "$lock")" >&2
        exit 1
    fi
    printf 'waiting for the inference slot, held by %s\n' "$(cat "$lock")" >&2
    flock 9
fi
printf 'pid %s since %s\n' "$$" "$(date +%s)" > "$lock"

chunks='
    ltrimstr("data: ")
    | select(. != "" and . != "[DONE]")
    | (try fromjson catch empty)
    | select(type == "object")
    | .choices[0]
'

send() {
    curl -sS -N \
        --config <(printf '%s\n' "$auth") \
        -H 'Content-Type: application/json' \
        --data-binary "@$tmp/payload" \
        --max-time 1200 \
        -w '\n%{http_code}' \
        "$url/chat/completions"
}

delay=2
code=000
for attempt in 1 2 3; do
    : > "$tmp/raw"

    if [ "$stream" = 1 ] && [ "$think" = 1 ]; then
        send | tee "$tmp/raw" \
            | tee >(jq --unbuffered -Rj "$chunks"' | .delta.reasoning_content // empty' >&2) \
            | jq --unbuffered -Rj "$chunks"' | .delta.content // empty' || true
    elif [ "$stream" = 1 ]; then
        send | tee "$tmp/raw" \
            | jq --unbuffered -Rj "$chunks"' | .delta.content // empty' || true
    else
        send > "$tmp/raw" || true
    fi

    code=$(tail -n1 "$tmp/raw")
    partial=0
    case "$(cat "$tmp/raw")" in
        *'"delta"'*) partial=1 ;;
    esac

    case "$code" in
        200) break ;;
        '' | 000 | 5*)
            if [ "$partial" = 1 ] || [ "$attempt" = 3 ]; then break; fi
            sleep "$delay"
            delay=$((delay * 3))
            ;;
        *) break ;;
    esac
done

head -n -1 "$tmp/raw" > "$tmp/body"

if [ "$code" != 200 ]; then
    if [ "$stream" = 1 ] && [ "$partial" = 1 ]; then
        printf '\nstream broke after partial output (http %s)\n' "$code" >&2
    elif [ -s "$tmp/body" ]; then
        jq -r 'if (.error | type) == "object" then (.error.message // "request failed")
               elif (.error | type) == "string" then .error
               else "request failed" end' "$tmp/body" >&2 2>/dev/null \
            || cat "$tmp/body" >&2
    else
        printf 'no response from %s (http %s)\n' "$url" "$code" >&2
    fi
    exit 1
fi

if [ "$stream" = 1 ]; then
    printf '\n'
elif [ "$raw" = 1 ]; then
    cat "$tmp/body"
else
    jq -r '.choices[0].message.content // ""' "$tmp/body"
fi

finish=$(jq -Rr "$chunks"' | .finish_reason // empty' "$tmp/raw" | tail -n1)

if [ "$finish" = length ]; then
    printf 'answer truncated at %s tokens (finish_reason=length); raise -m\n' \
        "$max_tokens" >&2
    if [ "$strict" = 1 ]; then
        exit 3
    fi
fi
