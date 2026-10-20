{ pkgs, ... } : {
    home.packages = with pkgs; [
        major-mono-display
        nerd-fonts.jetbrains-mono
        dejavu_fonts
        liberation_ttf
        noto-fonts-color-emoji
    ];

    fonts.fontconfig = {
        enable = true;

        defaultFonts = {
            monospace = [ "JetBrainsMono Nerd Font" "DejaVu Sans Mono" ];
            sansSerif = [ "DejaVu Sans" "Liberation Sans" ];
            serif = [ "DejaVu Serif" "Liberation Serif" ];
            emoji = [ "Noto Color Emoji" ];
        };

        hinting = "none";
        antialiasing = false;
    };
}
