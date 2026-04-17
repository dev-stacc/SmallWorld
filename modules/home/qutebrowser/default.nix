{ pkgs, lib, config, ... } : let
    colors = import ./colors.nix { inherit config lib pkgs; };
    window = import ./window.nix;
in {
    programs.qutebrowser = {
        enable = true;
        settings = lib.mkMerge [
            colors
            window
        ];
    };
}