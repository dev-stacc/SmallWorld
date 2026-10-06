wifi_menu() {
    while true; do
        STATE=$(iwctl station wlan0 show | awk '/State/ {print $2}')
        CONNECTED=$(iwctl station wlan0 show | awk '/Connected network/ {print $3}')
        NETWORKS=$(iwctl station wlan0 get-networks | tail -n +5 | \
            sed 's/\x1b\[[0-9;]*m//g' | awk '{print $1 " | " $2 " | " $3}' | grep -v "^\s*|" | grep -v "^$")
        
        SELECTION=$(printf 'turn on\nturn off\n\n%s' "$NETWORKS" | \
            fzf --height=100% --border=none --prompt="  wifi: " --header="<- esc" \
                --bind="esc:abort")
        
        [ -z "$SELECTION" ] && return
        
        case "$SELECTION" in
            "turn on") iwctl station wlan0 connect-hidden "" ;;
            "turn off") iwctl station wlan0 disconnect ;;
            *)
            SSID=$(echo "$SELECTION" | awk -F' | ' '{print $1}' | xargs)
            iwctl station wlan0 connect "$SSID"
            read -r -p "press enter to continue" ;;
        esac
    done
}

vpn_menu() {
    while true; do
        if tailscale status >/dev/null 2>&1; then
            TS_STATUS="on"
        else
            TS_STATUS="off"
        fi
        DEVICE=$(tailscale status --self 2>/dev/null | head -1 | awk '{print $1, $2}')
        
        SELECTION=$(printf 'tailscale: [%s]\n%s\n\nturn on\nturn on with exit node\nturn off' \
            "$TS_STATUS" "$DEVICE" | \
            fzf --height=100% --border=none --prompt="  vpn: " --header="<- esc" \
                --bind="esc:abort")
        
        case "$SELECTION" in
            "turn on") sudo tailscale up --exit-node= ;;
            "turn on with exit node") sudo tailscale up --exit-node=100.103.107.52 ;;
            "turn off") sudo tailscale down ;;
            *) return ;;
        esac
    done
}

bt_menu() {
    while true; do
        POWERED=$(bluetoothctl show | awk '/Powered/ {print $2}')
        CONNECTED=$(bluetoothctl info 2>/dev/null | awk '/Name/ {print $2}')
        DEVICES=$(bluetoothctl devices | sed 's/Device [^ ]* //' )
        
        SELECTION=$(printf 'turn on\nturn off\nscan\n\n%s' "$DEVICES" | \
            fzf --height=100% --border=none \
                --prompt="  bluetooth: " \
                --header="powered: [$POWERED] connected: [$CONNECTED]"$'\n'"<- esc" \
                --bind="esc:abort")
        
        [ -z "$SELECTION" ] && return
        
        case "$SELECTION" in
            "turn on") bluetoothctl power on ;;
            "turn off") bluetoothctl power off ;;
            "scan")
            bluetoothctl scan on &
            sleep 5
            kill %1
            ;;
            *)
            MAC=$(bluetoothctl devices | grep "$SELECTION" | awk '{print $2}')
            bluetoothctl connect "$MAC"
            read -r -p "press enter to continue"
            ;;
        esac
    done
}

main_menu() {
    while true; do
        SELECTION=$(printf 'wifi\nvpn\nbluetooth' | \
        fzf --height=100% --border=none --prompt="  control: " --bind="esc:abort")
        case "$SELECTION" in
            wifi) wifi_menu ;;
            vpn) vpn_menu ;;
            bluetooth) bt_menu ;;
            *) exit 0 ;;
        esac
    done
}

main_menu