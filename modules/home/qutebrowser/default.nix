{ pkgs, lib, config, ... } : let
    colors = import ./colors.nix { inherit config lib pkgs; };
    window = import ./window.nix { inherit config lib pkgs; };
in {
    programs.qutebrowser = {
        enable = true;
        settings = lib.mkMerge [
            colors
            window
            {
                content.user_stylesheets = ["${./user_stylesheet.css}"];
            }
        ];
    };
}