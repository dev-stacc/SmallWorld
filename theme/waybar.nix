{config, pkgs, ...}:
let
fanScript = pkgs.writeShellScript "fan-speed" ''
 HWMON=$(grep -rl "thinkpad" /sys/class/hwmon/*/name 2>/dev/null | head -1 | xargs dirname)
 if [ -n "$HWMON" ]; then
  FAN1=$(cat "$HWMON/fan1_input" 2>/dev/null)
  FAN2=$(cat "$HWMON/fan2_input" 2>/dev/null)
  if [ -n "$FAN1" ] && [ "$FAN1" -gt 0 ]; then
   echo "$FAN1"
  else
   echo "----"
  fi
 else
  echo "FIX YOUR FAN !!!"
 fi
'';
cpuBarsScript = pkgs.writeShellScript "cpu-bars" ''
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
'';
cpuTempScript = pkgs.writeShellScript "cpu-temps" ''
 TEMP_LOCATION=$(grep -rl "x86_pkg_temp" /sys/class/thermal/thermal_zone*/type 2>/dev/null | head -1 | xargs dirname)
 if [ -n "$TEMP_LOCATION" ]; then
  CPU_TEMP=$(cat "$TEMP_LOCATION/temp" 2>/dev/null)
  if [ -n "$CPU_TEMP" ]; then
   echo "$CPU_TEMP"
  else
   echo "FIX YOUR CPU TEMPS !!! (no temps)"
  fi
 else
  echo "FIX YOUR CPU TEMPS !!! (no sensor)"
 fi
'';
micMuteScript = pkgs.writeShellScript "mic-mute" ''
 MUTED=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -o "MUTED")
 if [ -n "$MUTED" ]; then
  echo ""
 else
  echo ""
 fi
'';

in {
 home.file.".local/bin/fan-speed" = {
  source = fanScript;
  executable = true;
 };
 programs.waybar = {
  enable = true;
  systemd.enable = true;
  settings = {
   mainBar = {
    layer = "top";
    position = "top";

    modules-left = [
     "group/cpu-usage"
     "group/cpu-temps"
    ];

    modules-center = [
     "group/audio"
     "backlight"  
     "hyprland/workspaces"
     "clock"
    ];

    modules-right = [
     "group/connect"
     "network"
     "battery"
     #"power"
    ];

    "group/cpu-usage" = {
     orientation = "horizontal";
     modules = ["cpu" "custom/cores"];
    };

    "group/cpu-temps" = {
     orientation = "horizontal";
     modules = ["temperature" "custom/fan"];
    };

    "group/audio" = {
     orientation = "horizontal";
     modules = ["wireplumber" "custom/mic"];
    };

    "group/connect" = {
     orientation = "horizontal";
     modules = ["bluetooth" "custom/tailscale"];
    };

    cpu = {
     format = "{usage}%";
     interval = 1;
     tooltip = false;
    };
 
    "custom/cores" = {
     exec = "${cpuBarsScript}";
     interval = 1;
     tooltip = false;
    };

    temperature = {
     exec = "${cpuTempScript}";
     format = "{}°C";
     interval = 2;
     tooltip = false;
    };

    "custom/fan" = {
     exec = "${fanScript}";
     format = "{} 󰈐 ";
     interval = 3;
     tooltip = false;
    };

    battery = {
     format = "{icon} {capacity}%";
     format-icons = [
      "󰁺" "󰁻" "󰁼" "󰁽" "󰁾"
      "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"
     ];
    };

    "wireplumber" = {
     format = "{icon}{volume}";
     format-muted = "󰝟 muted";
     format-icons = ["󰕿 " "󰖀 " "󰕾 " " "];
     tooltip = false;
    };

    "custom/mic" = { 
     exec = "${micMuteScript}";
     interval = 1;
     tooltip = false;
    };

    backlight = {
     format = "{icon} {percent}";
     format-icons = ["󱩎 " "󱩏 " "󱩐 " "󱩐 " "󱩒 " "󱩓 " "󱩔 " "󱩕 " "󱩖 "];
     tooltip = false;
    };

    "clock" = {
     format = "󰃭 {0:%d/%m/%Y}  {0:%H:%M}";
     tooltip = false;
    };

    "custom/tailscale" = {
     "exec" = "tailscale status >/dev/null 2>&1 && echo ' 󰒘 '|| echo ' 󰒙 '";
     "interval" = 3;
     "tooltip" = false;
    };

    "network" = {
     "format-wifi" = "{bandwidthDownBits} {bandwidthUpBits}";
     "format-ethernet" = "{bandwidthDownBits} {bandwidthUpBits}";
     "format-disconnected" = "󰤭 ";
     "format-disabled" = "󰤭 ";
     "tooltip" = false;
    };

    "bluetooth" = {
     "format" = "{icon}";
     "format-on" = " ";
     "format-connected" = " {device_alias}";
     "format-disabled" = "󰂯";
     "format-off" = "󰂯";
     "tooltip" = false;
    };
   };
  };
  style = ''
   window#waybar {
    background: transparent;
    background-image: linear-gradient(180deg, 
      rgba(0, 0, 0, 0.9) 3%,
      rgba(0, 0, 0, 0) 99%
    );
    margin: 0;
    margin-bottom: -6px;
    margin-top: -3px;
    color: white;
    font-size: 6px;
    font-family: "JetBrainsMono Nerd Font";
    min-height: 0;
   }
   
   * {
    padding-left: 9px;
    padding-right: 9px
   }
  '';
 };
}
