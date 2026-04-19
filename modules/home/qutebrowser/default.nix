{ pkgs, lib, config, ... } : let
    colors = import ./colors/default.nix { inherit config lib pkgs; };
    window = import ./window/default.nix { inherit config lib pkgs; };
    completion = import ./completion.nix { inherit config lib pkgs; };
    content = import ./content/default.nix { inherit config lib pkgs; };
    cssPath = (import ./content/default.nix { inherit config lib pkgs; }).finalCssPath;
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
            "style-on" = "set content.user_stylesheets [\"${cssPath}\"]";
            "style-off" = "set content.user_stylesheets []";
        };
    };
}