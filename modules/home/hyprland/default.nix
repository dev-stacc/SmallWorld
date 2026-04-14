{ config, lib, pkgs, self, inputs, ... } : let
    bind = import ./bind.nix;
    general = import ./general.nix;
    decoration = import ./decoration.nix;
    windowrule = import ./windowrule.nix;
    input = import ./input.nix;
in {
    wayland.windowManager.hyprland = {
        enable = true;
        monitor = [
            "eDP-1, 1920x1080@30, 0x0, 1"
        ];
        settings = lib.mkMerge [
            bind
            general
            decoration
            windowrule
            input
        ]
    };
}