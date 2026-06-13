{ lib, ... }:
let
    bind       = import ./bind.nix;
    general    = import ./general.nix;
    input      = import ./input.nix;
    output     = import ./output.nix;
    windowrule = import ./windowrule.nix;
in {
    wayland.windowManager.sway = {
        enable = true;
        config = lib.mkMerge [
            bind
            general
            input
            output
            windowrule
        ];
    };

    # replace hyprland/workspaces with sway/workspaces for antinoos
    programs.waybar.settings.mainBar = {
        modules-center = lib.mkForce [
            "group/audio"
            "sway/workspaces"
            "clock"
        ];
        "sway/workspaces" = {};
    };
}
