{ config, pkgs, lib, ... } :
let
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
    boot.initrd.kernelModules = [ "amdgpu" ];
    services.xserver.videoDrivers = [ "amdgpu" ];

    environment.sessionVariables = {
        LIBVA_DRIVER_NAME = "radeonsi";
    };

    hardware = {
        graphics = {
            enable = true;
            enable32Bit = true;
            extraPackages = with pkgs; [
                rocmPackages.clr.icd
                libva
                libva-utils
                libva-vdpau-driver
            ];
        };
        amdgpu.overdrive = {
            enable = true;
            ppfeaturemask = "0xffffffff";
        };
    };

    environment.systemPackages = with pkgs; [
        radeontop
    ];

    systemd.services.amdgpu-undervolt = {
        description = "AMD GPU undervolt (pp_od_clk_voltage)";
        wantedBy = [ "multi-user.target" ];
        after = [ "systemd-modules-load.service" ];
        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = pkgs.writeShellScript "amdgpu-undervolt" ''
                set -e
                CARD=""
                for c in /sys/class/drm/card*/device; do
                    [ -f "$c/vendor" ] || continue
                    [ "$(cat "$c/vendor")" = "0x1002" ] || continue
                    drv=$(basename "$(readlink "$c/driver")" 2>/dev/null)
                    [ "$drv" = "amdgpu" ] || continue
                    CARD="$c"; break
                done
                [ -z "$CARD" ] && { echo "no amdgpu card found"; exit 1; }

                OD="$CARD/pp_od_clk_voltage"
                [ -w "$OD" ] || { echo "$OD not writable"; exit 1; }

                ${lib.concatMapStringsSep "\n                " mkSclk sclkStates}
                ${lib.concatMapStringsSep "\n                " mkMclk mclkStates}
                echo 'c' > "$OD"

                echo auto > "$CARD/power_dpm_force_performance_level"
            '';
        };
    };

    systemd.services.amdgpu-fan = {
        description = "AMD GPU fan control";
        wantedBy = [ "multi-user.target" ];
        after = [ "systemd-modules-load.service" ];
        serviceConfig = {
            Type = "simple";
            Restart = "on-failure";
            ExecStart = pkgs.writeShellScript "amdgpu-fan" ''
                HWMON=""
                for h in /sys/class/drm/card*/device/hwmon/hwmon*; do
                    [ -f "$h/name" ] && grep -q "amdgpu" "$h/name" && HWMON="$h" && break
                done
                [ -z "$HWMON" ] && echo "no amdgpu hwmon found" && exit 1

                echo 1 > "$HWMON/pwm1_enable"
                trap 'echo 2 > "$HWMON/pwm1_enable"' EXIT

                while true; do
                    TEMP=$(( $(cat "$HWMON/temp1_input") / 1000 ))
                    if   [ "$TEMP" -lt 30 ]; then PWM=0
                    elif [ "$TEMP" -lt 75 ]; then PWM=$(( (TEMP - 30) * 255 / 45 ))
                    else PWM=255
                    fi
                    echo "$PWM" > "$HWMON/pwm1"
                    sleep 2
                done
            '';
        };
    };
}
