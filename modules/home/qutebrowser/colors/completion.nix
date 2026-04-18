{ config, lib, pkgs, ... } : let
    colors = config.stylix.base16Scheme;
in {
    completion = lib.mkForce {
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
}