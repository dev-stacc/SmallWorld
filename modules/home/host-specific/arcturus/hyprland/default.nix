{ lib, theme, ... } : let
    bind = import ./bind.nix;
    general = import ./general.nix { inherit theme; };
    decoration = import ./decoration.nix;
    windowrule = import ./windowrule.nix;
    input = import ./input.nix;
    monitor = import ./monitor.nix;
    misc = import ./misc.nix;
in {
    wayland.windowManager.hyprland = {
        enable = true;
        configType = "hyprlang";
        settings = lib.mkMerge [
            bind
            general
            decoration
            windowrule
            input
            monitor
            misc
        ];
    };
}
