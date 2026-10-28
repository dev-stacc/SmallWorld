#!/usr/bin/env bash
set -uo pipefail

sock="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/.socket2.sock"

count() {
    hyprctl -j activeworkspace 2>/dev/null | jq -r '.windows // 0'
}

count
[ -S "$sock" ] || exit 0

socat -u UNIX-CONNECT:"$sock" - 2>/dev/null | while read -r line; do
    case "$line" in
        openwindow*|closewindow*|workspace*|movewindow*|focusedmon*|fullscreen*) count ;;
    esac
done
