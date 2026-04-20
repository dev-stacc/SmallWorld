{ config, pkgs, inputs, ... }: {
    imports = [ inputs.stylix.nixosModules.stylix ];

    stylix = {
        enable = true;
        autoEnable = false;
        polarity = "dark";

        base16Scheme = {
            base00 = "0e0202"; #main BACKGROUND
            base01 = "000000"; #BLACK

            base02 = "ff4050"; #main FOREGROUND
            base03 = "98acf5"; #secondary FOREGROUND
            base04 = "ffe44d"; #highlight FOREGROUND
            base05 = "666666"; #muted FOREGROUND
            
            base06 = "000000"; #emphasis
            base07 = "000000"; #alert text?

            base08 = "000000"; #terminal current dir, also be alert bg for hyprland
            base09 = "000000"; ###
            base0A = "000000"; ###
            base0B = "000000"; #searchbar completion color

            base0C = "000000"; #alert text
            base0D = "000000"; #focused border
            base0E = "000000"; #terminal warning and folders
            base0F = "000000"; #same as comments basically
        };

        fonts = {
            monospace = {
                package = pkgs.departure-mono;
                name = "Departure Mono";
            };
            sansSerif = {
                package = pkgs.departure-mono;
                name = "Departure Mono";
            };
            serif = {
                package = pkgs.departure-mono;
                name = "Departure Mono";
            };
            sizes = {
                terminal = 11;
                applications = 11;
                desktop = 11;
                popups = 11;
            };
        }; 
    };
}