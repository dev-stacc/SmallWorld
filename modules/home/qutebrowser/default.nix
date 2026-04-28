{ pkgs, lib, config, fontName, fontSize, ... } : let
    colors = import ./colors/default.nix { inherit config lib pkgs; };
    window = import ./window/default.nix { inherit config lib pkgs; };
    completion = import ./completion.nix { inherit config lib pkgs; };
    content = import ./content/default.nix { inherit config lib pkgs fontName fontSize; };
    fileselect = import ./fileselect.nix { };
    css = (import ./content/generate-css.nix { inherit config lib pkgs fontName fontSize; }).cssPath;
in {
    programs.qutebrowser = {
        enable = true;
        settings = lib.mkMerge [
            colors
            window
            completion
            content
            fileselect
        ];
        
        aliases = {
            "darkmode" = "config-cycle colors.webpage.darkmode.enabled";
            "style-on" = "set content.user_stylesheets [${css}]";
            "style-off" = "set content.user_stylesheets []";
        };
    };
}
