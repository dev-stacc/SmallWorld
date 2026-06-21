{ ... } : {
    imports = [
        ../../common/all/default.nix
        ../../common/servers/always-on.nix
        ./k3s-server.nix
        ./flux.nix
        ./media.nix
        ./vault.nix
        ./suricata.nix
    ];

    networking.hostName = "Asta";

    boot.loader.grub = {
        enable = true;
        device = "/dev/sda";
    };

    swapDevices = [{
        device = "/swapfile";
        size = 16384;
    }];

    hardware.graphics = {
        enable = true;
    };

    services.xserver.videoDrivers = ["radeon"];
}
