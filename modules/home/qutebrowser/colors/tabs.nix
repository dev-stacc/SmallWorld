{ config, lib, pkgs, ... } : let
    colors = config.stylix.base16Scheme;
in {
    tabs = lib.mkForce {
        bar.bg = "#${colors.base02}";

        even = {
            bg = "#${colors.base02}";
            fg = "#${colors.base02}";
        };
        odd = {
            bg = "#${colors.base02}";
            fg = "#${colors.base02}";
        };

        selected = {
            even = {
                bg = "#${colors.base02}";
                fg = "#${colors.base00}";
            };
            odd = {
                bg = "#${colors.base02}";
                fg = "#${colors.base00}";
            };
        };
        
        pinned = {
            even = {
                bg = "#${colors.base02}";
                fg = "#${colors.base02}";
            };
            odd = {
                bg = "#${colors.base02}";
                fg = "#${colors.base02}";
            };

            selected = {
                even = {
                    bg = "#${colors.base02}";
                    fg = "#${colors.base00}";
                };
                odd = {
                    bg = "#${colors.base02}";
                    fg = "#${colors.base00}";
                };
            };
        };
        
        indicator = {
            error = "#${colors.base04}";
            system = "none";
        };
    };
}