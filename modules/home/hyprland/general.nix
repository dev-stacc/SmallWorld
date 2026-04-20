{ config, lib, pkgs, ... } : let
    colors = config.stylix.base16Scheme;
in {
    general = {
        gaps_in = 6;
        gaps_out = 9;
        border_size = 2;
        locale = "en_CA";
        layout = "master";
        "col.active_border" = "rgba(${colors.base02}ff)";
        "col.inactive_border" = "rgba(${colors.base01}00)";
    };
}