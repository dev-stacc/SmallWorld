{ ... } : {
    imports = [
        ../../common/all/default.nix
        ../../common/desktops/default.nix
        ./graphics.nix
        ./sunshine.nix
        ./storage.nix
    ];

    networking.hostName = "Antinoos";

    boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
    };
}
