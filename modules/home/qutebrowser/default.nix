{ pkgs, lib, config, ... } : let
    colors = import ./colors/default.nix { inherit config lib pkgs; };
    window = import ./window/default.nix { inherit config lib pkgs; };
    completion = import ./completion.nix { inherit config lib pkgs; };
    content = import ./content/default.nix { inherit config lib pkgs; };
    css = (import ./content/generate-css.nix { inherit config lib pkgs; }).cssPath;
in {
    programs.qutebrowser = {
        enable = true;
        settings = lib.mkMerge [
            colors
            window
            completion
            content
        ];
        
        aliases = {
            "style-on" = "set content.user_stylesheets [${css}]";
            "style-off" = "set content.user_stylesheets []";
        };
    };
}