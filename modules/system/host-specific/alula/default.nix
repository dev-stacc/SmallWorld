{ inputs, ... }: {
    imports = [
        ../../common/all/default.nix
        ../../common/desktops/default.nix
        ./niri.nix
        ./overlays.nix
    ];

    boot = {
        loader = {
            systemd-boot.enable = true;
            efi.canTouchEfiVariables = true;
        };
        kernelParams = [
            "usbcore.autosuspend=-1"
            "intel_idle.max_cstate=1"
            "irqpoll"
        ];
        blacklistedKernelModules = [
            "axp20x_i2c"
            "axp288_charger"
            "axp288_fuel_gauge"
            "axp288_adc"
        ];
    };

    hardware.enableRedistributableFirmware = true;

    networking.hostName = "Alula";
}
