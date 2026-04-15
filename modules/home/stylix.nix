{ pkgs, ... } : {
    stylix = {
        enable = true;
        autoEnable = false;
        polarity = "dark";
        image = ../wallpapers/stillPit.png;
        
        targets = {
            kitty.enable = true;
            hyprland.enable = true;
            gtk.enable = true;
        };
        
        fonts = {
            monospace = {
                package = pkgs.nerd-fonts.jetbrains-mono;
                name = "JetBrainsMono Nerd Font";
            };
            sansSerif = {
                package = pkgs.nerd-fonts.jetbrains-mono;
                name = "JetBrainsMono Nerd Font";
            };
            serif = {
                package = pkgs.nerd-fonts.jetbrains-mono;
                name = "JetBrainsMono Nerd Font";
            };
            sizes = {
                terminal = 9;
                applications = 9;
                desktop = 9;
                popups = 9;
            };
        };
    };
}