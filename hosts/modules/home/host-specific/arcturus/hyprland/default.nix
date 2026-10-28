{ lib, theme, ... } : let
    bind = import ./bind.nix;
    general = import ./general.nix { inherit theme; };
    animation = import ./animation.nix;
    decoration = import ./decoration.nix;
    layerrule = import ./layerrule.nix;
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
            animation
            decoration
            layerrule
            windowrule
            input
            monitor
            misc
        ];
    };
}
