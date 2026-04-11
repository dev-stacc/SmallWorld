{pkgs, lib, ...}:

{
 programs.kitty = {
  enable = true;
  enableGitIntegration = true;
  settings = {
   background_opacity = lib.mkForce "0.6";
  };
 };
 home.file.".local/bin/kitty-launcher" = {
  source = pkgs.writeShellScript "kitty-launcher" ''
   APPS=$(
    while IFS= read -r file; do
     NAME=$(grep -m1 -E "^Name=" "$file" | cut -d'=' -f2-)
     EXEC=$(grep -m1 -E "^Exec=" "$file" | cut -d'=' -f2- | sed 's/%[a-zA-Z]//g' | sed 's/--untrusted-args//g' | xargs)
     if [ -n "$NAME" ] && [ -n "$EXEC" ]; then
      printf '%s\t%s\n' "$NAME" "$EXEC"
     fi
     done < <(find -L \
      /run/current-system/sw/share/applications \
      "$HOME/.nix-profile/share/applications" \
      /etc/profiles/per-user/"$USER"/share/applications \
      "$HOME/.local/share/applications" \
      -maxdepth 1 -name "*.desktop" 2>/dev/null | sort -u)
    )

   SELECTION=$(printf '%s\n' "$APPS" | fzf --height=40% --border=none --prompt='  Launch: ')
    if [ -n "$SELECTION" ]; then
     COMMAND=$(printf '%s' "$SELECTION" | cut -f2-)
     hyprctl dispatch exec $COMMAND
     exit 0
    fi
   '';
  executable = true;
 };
 home.file.".local/bin/kitty-control" = {
  source = pkgs.writeShellScript "kitty-control" ''
   wifi_menu() {
    while true; do
     STATE=$(iwctl station wlan0 show | awk '/State/ {print $2}')
     CONNECTED=$(iwctl station wlan0 show | awk '/Connected network/ {print $3}')
     NETWORKS=$(iwctl station wlan0 get-networks | tail -n +5 | \
      sed 's/\x1b\[[0-9;]*m//g' | awk '{print $1 " | " $2 " | " $3}' | grep -v "^\s*|" | grep -v "^$")

     SELECTION=$(printf 'turn on\nturn off\n\n%s' "$NETWORKS" | \
      fzf --height=100% --border=none --prompt="  wifi: " --header="<- esc" --bind="esc:abort")

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
      fzf --height=100% --border=none --prompt="  vpn: " --header="<- esc" --bind="esc:abort")

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
  '';
  executable = true;
 };
home.file.".local/bin/kitty-status" = {
 source = pkgs.writeShellScript "kitty-status" ''
  CPU_BARS_SCRIPT="${pkgs.writeShellScript "cpu-bars" ''
   bars=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")
   mapfile -t s1 < <(awk '/^cpu[0-9]/{print $2+$3+$4+$5, $5}' /proc/stat)
   sleep 0.3
   mapfile -t s2 < <(awk '/^cpu[0-9]/{print $2+$3+$4+$5, $5}' /proc/stat)
   bar_str=""
   for i in ''${!s1[@]}; do
    read -r t1 i1 <<< "''${s1[$i]}"
    read -r t2 i2 <<< "''${s2[$i]}"
    dt=$((t2 - t1)); di=$((i2 - i1))
    usage=$(( dt > 0 ? (dt - di) * 100 / dt : 0 ))
    idx=$(( usage * 8 / 100 ))
    [ $idx -gt 7 ] && idx=7
    bar_str+="''${bars[$idx]}"
   done
   echo "$bar_str"
  ''}"

  FAN_SCRIPT="${pkgs.writeShellScript "fan-speed" ''
   HWMON=$(grep -rl "thinkpad" /sys/class/hwmon/*/name 2>/dev/null | head -1 | xargs dirname)
   if [ -n "$HWMON" ]; then
    FAN1=$(cat "$HWMON/fan1_input" 2>/dev/null)
    [ -n "$FAN1" ] && [ "$FAN1" -gt 0 ] && echo "$FAN1" || echo "----"
   else
    echo "NO FAN"
   fi
  ''}"
  
 while true; do
      # Gather variables (these stay as $VAR or $(cmd) - no braces needed)
      CPU_PERCENT=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}' | cut -d. -f1)
      CPU_BARS=$($CPU_BARS_SCRIPT)
      TEMP=$(cat /sys/class/thermal/thermal_zone1/temp 2>/dev/null | awk '{print $1/1000}' || echo "0")
      FAN=$($FAN_SCRIPT)
      
      # For VOL_ICON, use case statement or if/else
      VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print int($2 * 100)}')
      if wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -q "MUTED"; then
        VOL_ICON="🔇"
      elif [ "$VOL" -lt 30 ]; then
        VOL_ICON="🔈"
      elif [ "$VOL" -lt 70 ]; then
        VOL_ICON="🔉"
      else
        VOL_ICON="🔊"
      fi
      
      BAT=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo "0")
      if [ "$(cat /sys/class/power_supply/BAT0/status 2>/dev/null)" = "Charging" ]; then
        BAT_ICON="⚡"
      else
        [ "$BAT" -lt 20 ] && BAT_ICON="⚠️" || BAT_ICON="🔋"
      fi
      
      NET=$(nmcli -t -f STATE general 2>/dev/null | grep -q "connected" && echo "🌐" || echo "❌")
      BT=$(bluetoothctl show 2>/dev/null | grep -q "Powered: yes" && echo "" || echo "󰂯")
      TS=$(tailscale status >/dev/null 2>&1 && echo "󰒘" || echo "󰒙")
      DATE=$(date "+%d/%m/%Y")
      TIME=$(date "+%H:%M:%S")
      
      LEFT=" 󰻠 ''${CPU_PERCENT}% ''${CPU_BARS} 󰋼 ''${TEMP}°C 󰈐 ''${FAN}RPM "
      CENTER=" ''${VOL_ICON} ''${VOL}% ''${BAT_ICON} ''${BAT}% ''${NET} ''${BT} ''${TS} "
      RIGHT=" 󰃰 ''${TIME} 󰃭 ''${DATE} "
      
      # Clear and print
      clear
      printf "%s%*s%s%*s%s\n" "$LEFT" 10 "" "$CENTER" 10 "" "$RIGHT"
      
      sleep 1
    done  '';
  executable = true;
 };
}
