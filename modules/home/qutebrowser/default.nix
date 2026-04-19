{ pkgs, lib, config, ... } : let
    colors = import ./colors/default.nix { inherit config lib pkgs; };
    window = import ./window/default.nix { inherit config lib pkgs; };
    completion = import ./completion.nix;
in {
    programs.qutebrowser = {
        enable = true;
        settings = lib.mkMerge [
            colors
            window
            completion
            {
                content.user_stylesheets = ["${./user_stylesheet.css}"];
            }
        ];
    };
}