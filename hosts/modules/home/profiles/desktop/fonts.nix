{ pkgs, theme, ... } : {
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
            monospace = [ theme.fonts.monospace ];
            sansSerif = [ theme.fonts.sansSerif ];
            serif = [ theme.fonts.serif ];
            emoji = [ "Noto Color Emoji" ];
        };

        hinting = "none";
        antialiasing = false;
    };
}
