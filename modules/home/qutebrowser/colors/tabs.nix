{ config, lib, pkgs, ... } : let
    colors = config.stylix.base16Scheme;
in {
    tabs = lib.mkForce {
        bar.bg = "#${colors.base0D}";

        even = {
            bg = "#${colors.base0D}";
            fg = "#${colors.base0D}";
        };
        odd = {
            bg = "#${colors.base0D}";
            fg = "#${colors.base0D}";
        };

        selected = {
            even = {
                bg = "#${colors.base0D}";
                fg = "#${colors.base00}";
            };
            odd = {
                bg = "#${colors.base0D}";
                fg = "#${colors.base00}";
            };
        };
        
        pinned = {
            even = {
                bg = "#${colors.base0D}";
                fg = "#${colors.base0D}";
            };
            odd = {
                bg = "#${colors.base0D}";
                fg = "#${colors.base0D}";
            };

            selected = {
                even = {
                    bg = "#${colors.base0D}";
                    fg = "#${colors.base00}";
                };
                odd = {
                    bg = "#${colors.base0D}";
                    fg = "#${colors.base00}";
                };
            };
        };
        
        indicator = {
            error = "#${colors.base07}";
            system = "none";
        };
    };
}