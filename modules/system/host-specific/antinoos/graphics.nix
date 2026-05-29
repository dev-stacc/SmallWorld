{ config, pkgs, ... } : {
    boot.initrd.kernelModules = [ "amdgpu" ];
    services.xserver.videoDrivers = [ "amdgpu" ];

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

    programs.corectrl.enable = true;
    
    environment.systemPackages = with pkgs; [
        radeontop
    ];

    systemd.user.services.corectrl = {
        description = "corectrl gpu settings";
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        serviceConfig = {
            ExecStart = "${pkgs.corectrl}/bin/corectrl --minimize-systray";
            Restart = "on-failure";
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
