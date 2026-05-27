{ config, pkgs, inputs, ... }: {
    imports = [ inputs.stylix.nixosModules.stylix ];

    stylix = {
        enable = true;
        autoEnable = false;
        polarity = "dark";
        
        image = ../desktops/wallpapers/cyberpunk-bg.jpg;
        
        base16Scheme = {
            base00 = "0e0202"; #main BACKGROUND
            base01 = "000000"; #BLACK

            base02 = "ff4050"; #main FOREGROUND
            base03 = "00ccff"; #secondary FOREGROUND
            base04 = "ffe44d"; #highlight FOREGROUND
            base05 = "666666"; #muted FOREGROUND
            base06 = "6abf24"; #special FOREGROUND

            base07 = "000000"; #
            base08 = "000000"; #
            base09 = "000000"; #
            base0A = "000000"; #
            base0B = "000000"; #
            base0C = "000000"; #
            base0D = "000000"; #
            base0E = "000000"; #
            base0F = "000000"; #
        };

        fonts = {
            monospace = {
                package = pkgs.major-mono-display;
                name = "Major Mono Display";
            };
            sansSerif = {
                package = pkgs.major-mono-display;
                name = "Major Mono Display";
            };
            serif = {
                package = pkgs.major-mono-display;
                name = "Major Mono Display";
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
