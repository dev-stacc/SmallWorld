{ config, lib, pkgs, ... } : {
    imports = [
        ./common/all/default.nix
        ./common/servers/k3s-server.nix
        ./flux.nix
        ./media.nix
        ./vault.nix
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
