{ config, lib, pkgs, ... } : let
    colors = config.stylix.base16Scheme;
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
            category.border = lib.mkForce {
                bottom ="#${colors.base0D}";
                top = "#${colors.base0D}";
            };
        };
    };
}