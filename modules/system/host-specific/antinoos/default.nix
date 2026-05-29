{ config, pkgs, inputs, ... } : {
    imports = [
        ../../common/all/default.nix
        ../../common/desktops/default.nix
        ./graphics.nix
        ./overclock.nix
        ./sunshine.nix
        ./storage.nix
    ];

    networking.hostName = "Antinoos";

    boot = {
        loader.systemd-boot.enable = true;
        loader.efi.canTouchEfiVariables = true;
    };
}
