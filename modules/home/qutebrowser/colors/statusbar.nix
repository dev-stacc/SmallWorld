{ config, lib, pkgs, ... } : let
    colors = config.stylix.base16Scheme;
in {
    statusbar = lib.mkForce {
        normal = {
            bg = "#${colors.base00}";
            fg = "#${colors.base0D}";
        };
        
        private = {
            bg = "#${colors.base00}";
            fg = "#${colors.base0D}";
        };
        
        command = {
            bg = "#${colors.base0D}";
            fg = "#${colors.base00}";
        };
        
        command.private = {
            bg = "#${colors.base0D}";
            fg = "#${colors.base00}";
        };
        
        passthrough = {
            bg = "#${colors.base0D}";
            fg = "#${colors.base00}";
        };
        
        insert = {
            bg = "#${colors.base0D}";
            fg = "#${colors.base00}";
        };
        
        caret = {
            bg = "#${colors.base0D}";
            fg = "#${colors.base00}";
            selection = {
                bg = "#${colors.base0D}";
                fg = "#${colors.base00}";
            };
        };
    };
}