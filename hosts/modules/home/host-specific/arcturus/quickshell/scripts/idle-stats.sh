#!/usr/bin/env bash
set -uo pipefail

STATE=${XDG_RUNTIME_DIR:-/tmp}/qs-idle-cpu

cpu_usage() {
    local _ u n s i rest idle total pt pi dt di
    read -r _ u n s i rest < /proc/stat
    idle=$i
    total=$((u + n + s + i))
    for v in $rest; do total=$((total + v)); done
    if [ -r "$STATE" ]; then
        read -r pt pi < "$STATE"
        dt=$((total - pt)); di=$((idle - pi))
        if [ "$dt" -gt 0 ]; then echo $(((100 * (dt - di)) / dt)); else echo 0; fi
    else
        echo 0
    fi
    printf '%s %s\n' "$total" "$idle" > "$STATE"
}

hwmon_dir() {
    local hit
    hit=$(grep -rl "$1" /sys/class/hwmon/*/name 2>/dev/null | head -1)
    [ -n "$hit" ] && dirname "$hit"
}

cpu_temp() {
    local d raw
    d=$(hwmon_dir coretemp) || true
    [ -z "${d:-}" ] && { echo 0; return; }
    raw=$(cat "$d/temp1_input" 2>/dev/null)
    [ -z "$raw" ] && { echo 0; return; }
    echo $((raw / 1000))
}

mem_pct() {
    local t a
    t=$(awk '/^MemTotal:/{print $2}' /proc/meminfo)
    a=$(awk '/^MemAvailable:/{print $2}' /proc/meminfo)
    echo $(((t - a) * 100 / t))
}

mem_used() {
    local t a
    t=$(awk '/^MemTotal:/{print $2}' /proc/meminfo)
    a=$(awk '/^MemAvailable:/{print $2}' /proc/meminfo)
    awk -v u=$((t - a)) -v tt="$t" 'BEGIN{printf "%.1f/%.0f", u/1048576, tt/1048576}'
}

disk_pct() {
    df --output=pcent / 2>/dev/null | tail -1 | tr -dc '0-9'
}

uptime_short() {
    local s d h m
    s=$(awk '{print int($1)}' /proc/uptime)
    d=$((s / 86400)); h=$(((s % 86400) / 3600)); m=$(((s % 3600) / 60))
    if [ "$d" -gt 0 ]; then printf '%dd %dh' "$d" "$h"; else printf '%dh %dm' "$h" "$m"; fi
}

battery() { cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo 0; }
battery_state() { cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo Unknown; }

tailscale_up() {
    [ "$(tailscale status --json 2>/dev/null | jq -r '.BackendState // "Stopped"')" = "Running" ] && echo UP || echo DOWN
}

exit_node() {
    tailscale status --json 2>/dev/null \
        | jq -r 'if (.ExitNodeStatus // null) == null then "" else ([.Peer[]? | select(.ExitNode == true) | .HostName] | first // "ACTIVE") end' 2>/dev/null
}

printf '{"host":"%s","uptime":"%s","cpu":%s,"temp":%s,"mem":%s,"memused":"%s","disk":%s,"bat":%s,"batstate":"%s","ts":"%s","exit":"%s"}\n' \
    "$(hostname)" "$(uptime_short)" "$(cpu_usage)" "$(cpu_temp)" "$(mem_pct)" "$(mem_used)" \
    "$(disk_pct)" "$(battery)" "$(battery_state)" "$(tailscale_up)" "$(exit_node)"
