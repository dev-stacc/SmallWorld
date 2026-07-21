{ ... } : {
    imports = [
        ../../common/all/default.nix
        ../../common/desktops/default.nix
        ../../common/desktops/steam.nix
        ./graphics.nix
        ./storage.nix
        ./sway.nix
    ];

    networking.hostName = "Antinoos";

    boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
    };

    swapDevices = [{
        device = "/swapfile";
        size = 16384;
    }];
}
