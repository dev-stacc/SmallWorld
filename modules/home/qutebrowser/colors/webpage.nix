{ config, lib, pkgs, ... } : let
    colors = config.stylix.base16Scheme;
in {
    webpage = lib.mkForce {
        darkmode = {
            enabled = true;
            policy = {
                images = "never";
                page = "always";
            };
        };
        preferred_color_scheme = "dark";
        bg = "#${colors.base00}";
    };
}