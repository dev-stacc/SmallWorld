#!/usr/bin/env bash
set -uo pipefail

count() {
    hyprctl -j activeworkspace 2>/dev/null | jq -r '.windows // 0'
}

while :; do
    sock="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/.socket2.sock"
    count
    if [ -S "$sock" ]; then
        socat -u UNIX-CONNECT:"$sock" - 2>/dev/null | while read -r line; do
            case "$line" in
                openwindow*|closewindow*|workspace*|movewindow*|focusedmon*|fullscreen*) count ;;
            esac
        done
    fi
    sleep 2
done
