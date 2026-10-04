{ pkgs, theme, ... } : {
    home.packages = with pkgs; [
        major-mono-display
        nerd-fonts.jetbrains-mono
    ];

    fonts.fontconfig = {
        enable = true;
        
        defaultFonts = {
            monospace = [ theme.fonts.monospace ];
            sansSerif = [ theme.fonts.sansSerif ];
            serif = [ theme.fonts.serif ];
        };
        
        hinting = "none";
        antialiasing = false;
    };
}
