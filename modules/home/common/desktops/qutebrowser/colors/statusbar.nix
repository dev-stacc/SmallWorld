{ config, lib, pkgs, ... } : let
    colors = config.stylix.base16Scheme;
in {
    statusbar = lib.mkForce {
        normal = {
            bg = "#${colors.base02}";
            fg = "#${colors.base00}";
        };
        
        private = {
            bg = "#${colors.base02}";
            fg = "#${colors.base00}";
        };
        
        command = {
            bg = "#${colors.base02}";
            fg = "#${colors.base00}";
        };
        
        command.private = {
            bg = "#${colors.base02}";
            fg = "#${colors.base00}";
        };
        
        passthrough = {
            bg = "#${colors.base02}";
            fg = "#${colors.base00}";
        };
        
        insert = {
            bg = "#${colors.base02}";
            fg = "#${colors.base00}";
        };
        
        caret = {
            bg = "#${colors.base02}";
            fg = "#${colors.base00}";
            selection = {
                bg = "#${colors.base02}";
                fg = "#${colors.base00}";
            };
        };
        
        url = {
            fg = "#${colors.base00}";
            error.fg = "#${colors.base04}";
            hover.fg = "#${colors.base00}";
            success.http.fg = "#${colors.base00}";
            success.https.fg = "#${colors.base00}";
            warn.fg = "#${colors.base04}";
        };
    };
}