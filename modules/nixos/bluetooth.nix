{ config, pkgs, ... } : { 
    hardware.bluetooth = {
        enable = true;
        powerOnBoot = false;
        settings = {
            General = {
                ControllerMode = "dual";
                FastConnectable = "true";
                Experimental = "true";
            };
            Policy = {
                AutoEnable = "false";
            };
        };
    };

    boot.kernelModules = [
        "btusb"
        "bluetooth"
    ];

    environment.systemPackages = [
        pkgs.bluez
    ];
}
