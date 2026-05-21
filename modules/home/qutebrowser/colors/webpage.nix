{ config, lib, pkgs, ... } : let
    colors = config.stylix.base16Scheme;
in {
    webpage = lib.mkForce {
        bg = "transparent";
        darkmode = {
            enabled = true;
            policy = {
                images = "smart";
                page = "smart";
            };
        };
        preferred_color_scheme = "dark";
    };
}
