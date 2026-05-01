{ config, lib, pkgs, ... } : {
    imports = [
        ./common.nix
        ./k3s-server.nix
        ./flux.nix
    ];

    networking.hostName = "Asta";

    boot.loader.grub.enable = true;
    boot.loader.grub.device = "/dev/sda";

    swapDevices = [{
        device = "/swapfile";
       size = 8192;
    }];

    hardware.graphics = {
        enable = true;
    };

    services.xserver.videoDrivers = ["radeon"];
}
