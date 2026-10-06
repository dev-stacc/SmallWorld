{ pkgs, theme, ... } : let
    colors = theme.base16;
in {
    services.mako = {
        enable = true;
        package = pkgs.mako;
        settings = {
            "actionable=true" = {
                anchor = "top-right";
            };
            actions = false;
            history = false;
            anchor = "top-right";
            background-color = "#${colors.base00}FF";
            text-color = "#${colors.base02}FF";
            border-color = "#${colors.base00}00";
            border-radius = 0;
            border-size = 2;
            margin = 9;
            padding = 3;
            default-timeout = 6;
            font = "${theme.fonts.monospace}";
            icons = false;
            ignore-timeout = false;
            layer = "top";
        };
    };
}
