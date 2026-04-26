{ config, lib, pkgs, self, inputs, ... } : let
    bind = import ./bind.nix;
    general = import ./general.nix { inherit config lib pkgs; };
    decoration = import ./decoration.nix;
    windowrule = import ./windowrule.nix;
    input = import ./input.nix;
    monitor = import ./monitor.nix;
in {
    wayland.windowManager.hyprland = {
        enable = true;
        settings = lib.mkMerge [
            bind
            general
            decoration
            windowrule
            input
            monitor
            {
                "exec-once" = [
                    "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
                ];
                env = [
                    "INTEL_DEBUG,noccs"
                ];
            }
        ];
    };
}
