{ config, pkgs, inputs, ... } : {
    imports = [
        ../../common/all/default.nix
        ../../common/desktops/default.nix
#TEMPORARILY OUT, TAKE OUT WHEN READY ./graphics.nix
        ./sunshine
    ];

    networking.hostName = "Antinoos";

    boot = {
        loader.systemd-boot.enable = true;
        loader.efi.canTouchEfiVariables = true;
    };
}
