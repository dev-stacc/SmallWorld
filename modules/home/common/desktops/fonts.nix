{ config, pkgs, fontName, fontSize, ... } : {    
    home.packages = with pkgs; [
        major-mono-display
        nerd-fonts.jetbrains-mono
    ];

    fonts.fontconfig = {
        enable = true;
        
        defaultFonts = {
            monospace = [ fontName ];
            sansSerif = [ fontName ];
            serif = [ fontName ];
        };
        
        hinting = "none";
        antialiasing = false;
    };
}
