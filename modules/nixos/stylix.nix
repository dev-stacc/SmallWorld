{ config, pkgs, inputs, ... }: {
    imports = [ inputs.stylix.nixosModules.stylix ];

    stylix = {
        enable = true;
        autoEnable = true;
        polarity = "dark";
        
        base16Scheme = {
            base00 = "0e0202"; #terminal background
            base01 = "0e0202"; #bg tabs on qutebrowser apparently
            base02 = "664f4f"; #seems to be the actuall lighterbg
            base03 = "000000"; #unfocused window border, also bg highlight/selection
            
            base04 = "410909"; #comments basically? very muted
            base05 = "98acf5"; #regular text
            base06 = "ffe44d"; #emphasis
            base07 = "ffe44d"; #alert text?
            
            base08 = "ffe44d"; #terminal current dir, also be alert bg for hyprland
            base09 = "00ff88"; ###
            base0A = "00ffff"; ###
            base0B = "ffe44d"; #searchbar completion color
            
            base0C = "0e0202"; #alert text
            base0D = "ff4050"; #focused border
            base0E = "ff4050"; #terminal warning and folders
            base0F = "410909"; #same as comments basically
        };

        targets = {
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