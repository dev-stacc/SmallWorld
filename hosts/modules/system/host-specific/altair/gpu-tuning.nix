{ pkgs, lib, ... } : let
    sclkStates = [
        { level = 5; mhz = 1257; mv = 1050; }
        { level = 6; mhz = 1300; mv = 1100; }
        { level = 7; mhz = 1340; mv = 1150; }
    ];

    mclkStates = [
        { level = 2; mhz = 2000; mv = 950; }
    ];

    mkSclk = s: "echo 's ${toString s.level} ${toString s.mhz} ${toString s.mv}' > \"$OD\"";
    mkMclk = s: "echo 'm ${toString s.level} ${toString s.mhz} ${toString s.mv}' > \"$OD\"";
in {
    hardware.amdgpu.overdrive.enable = true;

    systemd.services.amdgpu-undervolt = {
        description = "AMD GPU undervolt (pp_od_clk_voltage)";
        wantedBy = [ "multi-user.target" ];
        after = [ "systemd-modules-load.service" ];
        path = with pkgs; [ coreutils ];

        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = pkgs.writeShellScript "amdgpu-undervolt" ''
                set -e

                TUNED=0
                for c in /sys/class/drm/card*/device; do
                    [ -f "$c/vendor" ] || continue
                    [ "$(cat "$c/vendor")" = "0x1002" ] || continue
                    drv=$(basename "$(readlink "$c/driver")" 2>/dev/null)
                    [ "$drv" = "amdgpu" ] || continue

                    OD="$c/pp_od_clk_voltage"
                    [ -w "$OD" ] || continue

                    ${lib.concatMapStringsSep "\n                    " mkSclk sclkStates}
                    ${lib.concatMapStringsSep "\n                    " mkMclk mclkStates}
                    echo 'c' > "$OD"

                    echo auto > "$c/power_dpm_force_performance_level"
                    TUNED=$((TUNED + 1))
                done

                if [ "$TUNED" -eq 0 ]; then
                    echo "no writable amdgpu card found"
                    exit 1
                fi

                echo "tuned $TUNED card(s)"
            '';
        };
    };

    systemd.services.amdgpu-fan = {
        description = "AMD GPU fan control";
        wantedBy = [ "multi-user.target" ];
        after = [ "systemd-modules-load.service" ];
        path = with pkgs; [ coreutils gnugrep ];

        serviceConfig = {
            Type = "simple";
            Restart = "on-failure";
            ExecStart = pkgs.writeShellScript "amdgpu-fan" ''
                HWMONS=""
                for h in /sys/class/drm/card*/device/hwmon/hwmon*; do
                    [ -f "$h/name" ] || continue
                    grep -q amdgpu "$h/name" || continue
                    [ -w "$h/pwm1_enable" ] || continue
                    HWMONS="$HWMONS $h"
                done

                if [ -z "$HWMONS" ]; then
                    echo "no amdgpu hwmon found"
                    exit 1
                fi

                restore() {
                    for h in $HWMONS; do
                        echo 2 > "$h/pwm1_enable" || true
                    done
                }
                trap restore EXIT

                for h in $HWMONS; do
                    echo 1 > "$h/pwm1_enable"
                done

                while true; do
                    for h in $HWMONS; do
                        TEMP=$(( $(cat "$h/temp1_input") / 1000 ))
                        if   [ "$TEMP" -lt 30 ]; then PWM=0
                        elif [ "$TEMP" -lt 75 ]; then PWM=$(( (TEMP - 30) * 255 / 45 ))
                        else PWM=255
                        fi
                        echo "$PWM" > "$h/pwm1"
                    done
                    sleep 2
                done
            '';
        };
    };
}
