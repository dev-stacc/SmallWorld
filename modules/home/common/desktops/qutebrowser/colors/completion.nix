{ config, lib, pkgs, ... } : let
    colors = config.stylix.base16Scheme;
in {
    completion = lib.mkForce {
        even.bg = "#${colors.base00}";
        odd.bg = "#${colors.base00}";
        fg = "#${colors.base02}";
        match.fg ="#${colors.base04}";
        
        item.selected = {
            border = {
                bottom ="#${colors.base00}";
                top = "#${colors.base00}";
            };
            bg = "#${colors.base02}";
            fg = "#${colors.base00}";
            match.fg = "#${colors.base04}";
        };
        
        category = {
            border = {
                bottom ="#${colors.base00}";
                top = "#${colors.base02}";
            };
            bg = "#${colors.base00}";
            fg = "#${colors.base02}";
        };
        
        scrollbar = {
            bg = "#${colors.base00}";
            fg = "#${colors.base00}";
        };
    };
}