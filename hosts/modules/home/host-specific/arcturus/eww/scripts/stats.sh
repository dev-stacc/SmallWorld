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

hwmon_dir() {
    local hit
    hit=$(grep -rl "$1" /sys/class/hwmon/*/name 2>/dev/null | head -1)
    [ -n "$hit" ] && dirname "$hit"
}

cpu_temp() {
    local d raw
    d=$(hwmon_dir coretemp)
    [ -z "$d" ] && { echo "--"; return; }
    raw=$(cat "$d/temp1_input" 2>/dev/null)
    [ -z "$raw" ] && { echo "--"; return; }
    echo $((raw / 1000))
}

fan_speed() {
    local d raw
    d=$(hwmon_dir thinkpad)
    [ -z "$d" ] && { echo "--"; return; }
    raw=$(cat "$d/fan1_input" 2>/dev/null)
    [ -z "$raw" ] && { echo "--"; return; }
    echo "$raw"
}

ram_used() {
    local total avail used
    total=$(awk '/^MemTotal:/{print $2}' /proc/meminfo)
    avail=$(awk '/^MemAvailable:/{print $2}' /proc/meminfo)
    used=$((total - avail))
    awk -v u="$used" 'BEGIN{printf "%.1f", u/1048576}'
}

tailscale_state() {
    tailscale status >/dev/null 2>&1 && echo "UP" || echo "DOWN"
}

bluetooth_state() {
    case "$(bluetoothctl show 2>/dev/null | awk '/Powered:/ {print $2; exit}')" in
        yes) echo "ON" ;;
        *)   echo "OFF" ;;
    esac
}

wifi_signal() {
    local q
    if rfkill list wifi 2>/dev/null | grep -q 'blocked: yes'; then
        echo "OFF"
        return
    fi
    q=$(awk '/wlan|wlp/ {gsub(/\./,"",$3); print $3; exit}' /proc/net/wireless 2>/dev/null)
    [ -z "$q" ] && { echo "OFF"; return; }
    echo $((q * 100 / 70))
}

battery() {
    cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo 0
}

battery_state() {
    cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo "Unknown"
}

volume() {
    local raw
    raw=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null) || { echo "--"; return; }
    awk '{printf "%d", $2*100}' <<<"$raw"
}

brightness() {
    brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%' || echo "--"
}

clock() {
    date +%H:%M
}

workspace() {
    hyprctl -j activeworkspace 2>/dev/null | sed -n 's/.*"id": *\([0-9-]*\).*/\1/p' | head -1
}

printf '{"cpu":"%s","temp":"%s","fan":"%s","bat":%s,"batstate":"%s","ram":"%s","wifi":"%s","ts":"%s","bt":"%s","ws":"%s","time":"%s","vol":"%s","bri":"%s"}\n' \
    "$(cpu_usage)" \
    "$(cpu_temp)" \
    "$(fan_speed)" \
    "$(battery)" \
    "$(battery_state)" \
    "$(ram_used)" \
    "$(wifi_signal)" \
    "$(tailscale_state)" \
    "$(bluetooth_state)" \
    "$(workspace)" \
    "$(clock)" \
    "$(volume)" \
    "$(brightness)"
