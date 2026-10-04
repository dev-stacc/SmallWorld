{ lib, ... }:
let
    bind       = import ./bind.nix;
    general    = import ./general.nix;
    input      = import ./input.nix;
    windowrule = import ./windowrule.nix;
in {
    wayland.windowManager.sway = {
        enable = true;
        config = lib.mkMerge [
            bind
            general
            input
            windowrule
        ];
    };
}
