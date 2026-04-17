{ config, lib, pkgs, ... } : let
    colors = config.stylix.colors;
in {
    colors = {
        webpage.darkmode = {
            enabled = true;
            policy = {
                images = "never";
                page = "always";
            };
        };
        completion = {
            category.border.top = "${colors.base0D}";
        };
    };
}