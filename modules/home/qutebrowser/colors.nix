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
            };
            preferred_color_scheme = "dark";
            bg = "#${colors.base00}";
        };
        
        
        
        completion = {
            even.bg = "#${colors.base00}";
            odd.bg = "#${colors.base00}";
            fg = "#${colors.base0D}";
            match.fg ="#${colors.base07}";
            
            item.selected = {
                border = {
                    bottom ="#${colors.base00}";
                    top = "#${colors.base00}";
                };
                bg = "#${colors.base0D}";
                fg = "#${colors.base00}";
                match.fg = "#${colors.base07}";
            };
            
            category = {
                border = {
                    bottom ="#${colors.base00}";
                    top = "#${colors.base0D}";
                };
                bg = "#${colors.base00}";
                fg = "#${colors.base0D}";
            };
            
            scrollbar = {
                bg = "#${colors.base00}";
                fg = "#${colors.base00}";
            };
        };
        
        
        
    };
}