{ config, lib, pkgs, ... } : let
    colors = config.stylix.base16Scheme;
in {
    tooltip = lib.mkForce {
        bg = "#${colors.base00}";
        fg = "#${colors.base0D}";
    };
}