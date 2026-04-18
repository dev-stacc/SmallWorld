{ config, lib, pkgs, ... } : let
    colors = config.stylix.base16Scheme;
in {
    colors = lib.mkForce {
        webpage = {
            darkmode = {
                enabled = true;
                policy = {
                    images = "never";
                    page = "always";
                };
                ppreferred_color_scheme = "dark";
            };
            bg = "#${colors.base00}99";
        };
        completion = {
            category.border = {
                bottom ="#${colors.base0D}";
                top = "#${colors.base0D}";
            };
        };
    };
}