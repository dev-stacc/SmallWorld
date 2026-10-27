#!/usr/bin/env bash
set -uo pipefail

STATE=${XDG_RUNTIME_DIR:-/tmp}/eww-cpu-sample

cpu_usage() {
    local _ u n s i rest idle total prev_total prev_idle dt di
    read -r _ u n s i rest < /proc/stat
    idle=$i
    total=$((u + n + s + i))
    for v in $rest; do total=$((total + v)); done

    if [ -r "$STATE" ]; then
        read -r prev_total prev_idle < "$STATE"
        dt=$((total - prev_total))
        di=$((idle - prev_idle))
        if [ "$dt" -gt 0 ]; then
            echo $(((100 * (dt - di)) / dt))
        else
            echo 0
        fi
    else
        echo 0
    fi
    printf '%s %s\n' "$total" "$idle" > "$STATE"
}

cpu_temp() {
    local hwmon raw
    hwmon=$(grep -rl coretemp /sys/class/hwmon/*/name 2>/dev/null | head -1)
    [ -z "$hwmon" ] && { echo "--"; return; }
    raw=$(cat "$(dirname "$hwmon")/temp1_input" 2>/dev/null)
    [ -z "$raw" ] && { echo "--"; return; }
    echo $((raw / 1000))
}

ram_used() {
    local total avail used
    total=$(awk '/^MemTotal:/{print $2}' /proc/meminfo)
    avail=$(awk '/^MemAvailable:/{print $2}' /proc/meminfo)
    used=$((total - avail))
    awk -v u="$used" 'BEGIN{printf "%.1f", u/1048576}'
}

volume() {
    local raw
    raw=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null) || { echo "--"; return; }
    awk '{printf "%d", $2*100}' <<<"$raw"
}

brightness() {
    brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%' || echo "--"
}

tailscale_state() {
    tailscale status >/dev/null 2>&1 && echo "UP" || echo "DOWN"
}

wifi_signal() {
    local q
    q=$(awk '/:/ {gsub(/\./,"",$3); print $3; exit}' /proc/net/wireless 2>/dev/null)
    [ -z "$q" ] && { echo "--"; return; }
    echo $((q * 100 / 70))
}

battery() {
    local cap
    cap=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)
    [ -z "$cap" ] && { echo "--"; return; }
    echo "$cap"
}

printf '{"cpu":"%s","temp":"%s","ram":"%s","vol":"%s","bri":"%s","time":"%s","ts":"%s","wifi":"%s","bat":"%s"}\n' \
    "$(cpu_usage)" \
    "$(cpu_temp)" \
    "$(ram_used)" \
    "$(volume)" \
    "$(brightness)" \
    "$(date +%H:%M)" \
    "$(tailscale_state)" \
    "$(wifi_signal)" \
    "$(battery)"
