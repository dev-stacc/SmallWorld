{ pkgs, lib, config, fontName, fontSize, ... } : let
    kittyLauncher = pkgs.writeShellScript "kitty-launcher" (builtins.readFile ./scripts/kitty-launcher.sh);
    kittyControl = pkgs.writeShellScript "kitty-control" (builtins.readFile ./scripts/kitty-control.sh);
    colors = config.stylix.base16Scheme;
in {
    programs.kitty = {
        enable = true;
        enableGitIntegration = true;
        settings = lib.mkForce {
            background_opacity = "0.6";
            color0 = "#${colors.base00}";
            color1 = "#${colors.base04}";
            color2 = "#${colors.base03}";
            color3 = "#${colors.base03}";
            color4 = "#${colors.base04}";
            color5 = "#${colors.base04}";
            color6 = "#${colors.base03}";
            color7 = "#${colors.base02}";
            
            color8 = "#${colors.base00}";
            color9 = "#${colors.base04}";
            color10 = "#${colors.base03}";
            color11 = "#${colors.base03}";
            color12 = "#${colors.base04}";
            color13 = "#${colors.base04}";
            color14 = "#${colors.base03}";
            color15 = "#${colors.base02}";
            
            foreground = "#${colors.base02}";
            background = "#${colors.base00}";
            
            selection_foreground = "#${colors.base02}";
            selection_background = "#${colors.base01}";
            
            active_tab_background = "#${colors.base02}";
            active_tab_foreground = "#${colors.base00}";
            inactive_tab_background = "#${colors.base02}";
            inactive_tab_foreground = "#${colors.base02}";
            
            url_color = "#${colors.base03}";
            
            cursor = "#${colors.base02}";
            cursor_text_color = "#${colors.base00}";
            
            window_padding_width = 6;
            
            font_family = fontName;
            font_size = fontSize;
            
        };
    };
  
    home.file = {
        ".local/bin/kitty-launcher" = {
            source = kittyLauncher;
            executable = true;
        };
        ".local/bin/kitty-control" = {
            source = kittyControl;
            executable = true;
        };
    };
}