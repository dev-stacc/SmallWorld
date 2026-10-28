#!/usr/bin/env bash
set -uo pipefail

clean() {
    sed 's/^\.//; s/-\(un\)\?wrapp.*$//' <<<"$1" | tr '[:upper:]' '[:lower:]'
}

first=1
printf '{'
while read -r kpid; do
    [ -z "$kpid" ] && continue
    label="terminal"
    while read -r shellpid shellcomm; do
        [ "$shellcomm" = "bash" ] || continue
        child=$(ps --ppid "$shellpid" -o comm= --no-headers 2>/dev/null | head -1)
        [ -n "$child" ] && label=$(clean "$child")
    done < <(ps --ppid "$kpid" -o pid=,comm= --no-headers 2>/dev/null)

    [ $first -eq 0 ] && printf ','
    first=0
    printf '"%s":"%s"' "$kpid" "$label"
done < <(ps -eo pid=,comm= --no-headers 2>/dev/null | awk '$2 ~ /kitty/ {print $1}')
printf '}\n'
