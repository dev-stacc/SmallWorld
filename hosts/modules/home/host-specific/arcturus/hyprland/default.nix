{ lib, pkgs, theme, ... } : let
    bind = import ./bind.nix;
    general = import ./general.nix { inherit theme; };
    animation = import ./animation.nix { inherit theme; };
    decoration = import ./decoration.nix;
    layerrule = import ./layerrule.nix;
    windowrule = import ./windowrule.nix;
    input = import ./input.nix;
    monitor = import ./monitor.nix;
    misc = import ./misc.nix;

    switch-layout = import ./switch-layout.nix { inherit pkgs; };
in {
    home.packages = [ switch-layout ];

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
