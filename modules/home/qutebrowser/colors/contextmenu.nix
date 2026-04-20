{ config, lib, pkgs, ... } : let
    colors = config.stylix.base16Scheme;
in {
    contextmenu = lib.mkForce {
        disabled = {
            bg = "#${colors.base00}";
            fg = "#${colors.base02}";
        };
        menu = {
            bg = "#${colors.base00}";
            fg = "#${colors.base02}";
        };
        selected = {
            bg = "#${colors.base00}";
            fg = "#${colors.base02}";
        };
    };
}