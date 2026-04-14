{ config, pkgs, inputs, ... }: {
    imports = [ inputs.stylix.nixosModules.stylix ];

    stylix = {
        enable = true;
        image = ./wallpapers/your-image.png;
        polarity = "dark";
    
        fonts.monospace = {
            package = pkgs.nerd-fonts.jetbrains-mono;
            name = "JetBrainsMono Nerd Font";
        };
    };
}