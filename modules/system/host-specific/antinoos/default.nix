{ inputs, pkgs, lib, ... } : {
    imports = [
        ../../common/all/default.nix
        ../../common/desktops/default.nix
        ./graphics.nix
        ./storage.nix
    ];

    networking.hostName = "Antinoos";

    programs.hyprland.package = lib.mkForce
        inputs.hyprland-legacy.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    programs.hyprland.portalPackage = lib.mkForce
        inputs.hyprland-legacy.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;

    boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
    };
}
