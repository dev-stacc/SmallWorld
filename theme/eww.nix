{ config, pkgs, ... }:
let
  # Your existing scripts (unchanged)
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

  # EWW Yuck configuration
  ewwConfig = pkgs.writeText "eww.yuck" ''
    (defwidget bar []
      (box :orientation "v" :class "bar"
        (centerbox
          :class "centerbox"
          :halign "center" :vexpand true

          (box :class "left" :halign "start" :spacing 10
            (cpu-usage)
            (cpu-temps)
          )


          (box :class "center" :halign "center" :spacing 15
            (audio)
            (backlight)
            (workspaces)
            (clock)
          )


          (box :class "right" :halign "end" :spacing 10
            (bluetooth)
            (tailscale)
            (network)
            (battery)
          )
        )
      )
    )


    (defwidget cpu-usage []
      (box :class "cpu-usage" :halign "start" :spacing 5
        (cpu-percent)
        (cpu-cores)
      )
    )

    (defwidget cpu-percent []
      (script :class "cpu-percent" :interval 1 "bash" "-c" "top -bn1 | grep 'Cpu(s)' | awk '{print 100 - $8}' | cut -d. -f1")
    )

    (defwidget cpu-cores []
      (script :class "cpu-cores" :interval 1 "${cpuBarsScript}")
    )


    (defwidget cpu-temps []
      (box :class "cpu-temps" :halign "start" :spacing 5
        (cpu-temp)
        (fan-speed)
      )
    )

    (defwidget cpu-temp []
      (script :class "cpu-temp" :interval 2 "bash" "-c" "echo $(($(${cpuTempScript}) / 1000))°C")
    )

    (defwidget fan-speed []
      (script :class "fan-speed" :interval 3 "${fanScript}")
    )


    (defwidget audio []
      (box :class "audio" :halign "center" :spacing 5
        (volume)
        (mic)
      )
    )

    (defwidget volume []
      (script :class "volume" :interval 1
        :onclick "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        :onrightclick "pavucontrol"
        "bash" "-c" "
          VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}')
          MUTED=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -o MUTED)
          if [ -n \"$MUTED\" ]; then
            echo '󰝟'
          else
            if [ $VOL -lt 30 ]; then echo '󰕿 $VOL%'
            elif [ $VOL -lt 70 ]; then echo '󰖀 $VOL%'
            else echo '󰕾 $VOL%'
            fi
          fi
        "
      )
    )

    (defwidget mic []
      (script :class "mic" :interval 1
        :onclick "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        "${micMuteScript}"
      )
    )


    (defwidget backlight []
      (script :class "backlight" :interval 2
        "bash" "-c" "
          BRIGHT=$(brightnessctl g)
          MAX=$(brightnessctl m)
          PERCENT=$((BRIGHT * 100 / MAX))
          if [ $PERCENT -lt 20 ]; then ICON='󱩎'
          elif [ $PERCENT -lt 40 ]; then ICON='󱩏'
          elif [ $PERCENT -lt 60 ]; then ICON='󱩐'
          elif [ $PERCENT -lt 80 ]; then ICON='󱩓'
          else ICON='󱩖'
          fi
          echo \"$ICON $PERCENT%\"
        "
      )
    )


    (defwidget workspaces []
      (box :class "workspaces" :halign "center" :spacing 5
        (button :onclick "hyprctl dispatch workspace 1" "1")
        (button :onclick "hyprctl dispatch workspace 2" "2")
        (button :onclick "hyprctl dispatch workspace 3" "3")
        (button :onclick "hyprctl dispatch workspace 4" "4")
        (button :onclick "hyprctl dispatch workspace 5" "5")
      )
    )


    (defwidget clock []
      (script :class "clock" :interval 60
        "bash" "-c" "date '+󰃭 %d/%m/%Y 󰥔 %H:%M'"
      )
    )


    (defwidget tailscale []
      (script :class "tailscale" :interval 3
        "bash" "-c" "tailscale status >/dev/null 2>&1 && echo '󰒘' || echo '󰒙'"
      )
    )


    (defwidget network []
      (script :class "network" :interval 2
        "bash" "-c" "
          if nmcli -t -f STATE general | grep -q 'connected'; then
            RX=$(cat /sys/class/net/*/statistics/rx_bytes 2>/dev/null | awk '{sum+=\$1} END {print sum}')
            TX=$(cat /sys/class/net/*/statistics/tx_bytes 2>/dev/null | awk '{sum+=\$1} END {print sum}')
            echo \"󰀂 $((RX/1024/1024))M 󰀁 $((TX/1024/1024))M\"
          else
            echo '󰤭'
          fi
        "
      )
    )


    (defwidget bluetooth []
      (script :class "bluetooth" :interval 3
        :onclick "rfkill toggle bluetooth"
        "bash" "-c" "
          if rfkill list bluetooth | grep -q 'Soft blocked: yes'; then
            echo '󰂯'
          else
            DEVICE=$(bluetoothctl info | grep 'Name' | cut -d: -f2 | xargs)
            if [ -n \"$DEVICE\" ]; then
              echo \"󰊓 $DEVICE\"
            else
              echo '󰊓'
            fi
          fi
        "
      )
    )


    (defwidget battery []
      (script :class "battery" :interval 10
        "bash" "-c" "
          CAP=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)
          STATUS=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null)
          ICONS=('󰁺' '󰁻' '󰁼' '󰁽' '󰁾' '󰁿' '󰂀' '󰂁' '󰂂' '󰁹')
          IDX=$((CAP * 9 / 100))
          if [ \"$STATUS\" = 'Charging' ]; then
            echo \"󰂄 $CAP%\"
          else
            echo \"''${ICONS[$IDX]} $CAP%\"
          fi
        "
      )
    )


    (defwindow bar
      :monitor 0
      :windowtype "dock"
      :stacking "overlay"
      :geometry (geometry :x "5%" :y "0%" :width "90%" :height "45px"
                 :anchor "top center")
      :reserve (struts :side "top" :distance "45")
      :wm-ignore true
      bar
    )
  '';

  # EWW SCSS styling
  ewwScss = pkgs.writeText "eww.scss" ''
    * {
      all: unset;
    }

    .bar {
      background-color: rgba(30, 30, 46, 0.85);
      border-radius: 0;
      padding: 5px 10px;
    }

    .centerbox {
      background-color: transparent;
    }

    .left, .center, .right {
      background-color: transparent;
    }

    /* Module base styling */
    .cpu-usage, .cpu-temps, .audio, .backlight, .workspaces,
    .clock, .network, .battery, .bluetooth, .tailscale {
      background-color: rgba(0, 0, 0, 0.3);
      border-radius: 8px;
      padding: 4px 12px;
      margin: 0 2px;
    }

    /* Individual widget styling */
    .cpu-percent, .cpu-cores, .cpu-temp, .fan-speed {
      font-weight: bold;
    }

    .cpu-cores {
      font-family: monospace;
      letter-spacing: 2px;
    }

    .volume, .mic {
      margin: 0 2px;
    }

    .workspaces button {
      background: transparent;
      margin: 0 4px;
      min-width: 20px;
    }

    .workspaces button.active {
      color: #89b4fa;
    }
  '';

  # Compiled CSS from SCSS
  ewwCss = pkgs.runCommand "eww.css" {
    buildInputs = [ pkgs.sassc ];
  } ''
    sassc ${ewwScss} $out
  '';

in {
  home.packages = with pkgs; [ eww ];
  home.file.".config/eww/eww.yuck" = {
    source = ewwConfig;
  };
  home.file.".config/eww/eww.css" = {
    source = ewwCss;
  };
}
