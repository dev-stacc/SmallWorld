{ config, pkgs, fontName, ... } : let
    colors = config.stylix.base16Scheme;
in {
    services.mako = {
        enable = true;
        package = pkgs.mako;
        settings = {
            "actionable=true" = {
                anchor = "top-right"
            };
            actions = false;
            history = false;
            anchor = "top-right";
            background-color = "#${colors.base00}AA";
            text-color = "#${colors.base02}FF";
            border-color = "#${colors.base02}FF";
            border-radius = 0;
            border-size = 2;
            default-timeout = 6;
            font = "${fontName}";
            icons = false;
            ignore-timeout = false;
            layer = "top";
            margin = 3;
        };
    };
}
