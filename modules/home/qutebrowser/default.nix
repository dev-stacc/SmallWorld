{ pkgs, lib, config, ... } : let
    colors = import ./colors/default.nix { inherit config lib pkgs; };
    window = import ./window/default.nix { inherit config lib pkgs; };
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