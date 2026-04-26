{ config, pkgs, fontName, ... } : let
    colors = config.stylix.base16Scheme;
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
            font = "${fontName}";
            icons = false;
            ignore-timeout = false;
            layer = "top";
        };
    };
}
