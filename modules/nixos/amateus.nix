{ config, lib, pkgs, ... } : {
    imports = [
        ./common.nix
    ];

    networking.hostName = "Amateus";

    boot.loader.grub.enable = true;
    boot.loader.grub.device = "/dev/sda";

    swapDevices = [{
        device = "/swapfile";
       size = 8192;
    }];

    hardware.graphics = {
        enable = true;
    };
}
