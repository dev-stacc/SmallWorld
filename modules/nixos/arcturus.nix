{ config, pkgs, inputs, ... } : {
    imports = [
        ./common.nix
        ./bluetooth.nix
        ./sound.nix
        ./hyprland.nix
        ./stylix.nix
        ./overlays.nix
        ./unfreePredicates.nix
    ];

    networking.hostName = "Arcturus";

    boot = {
        loader.systemd-boot.enable = true;
        loader.efi.canTouchEfiVariables = true;
    };

    hardware.graphics = {
        enable = true;
        extraPackages = with pkgs; [
            intel-media-driver
        ];
    };
}
