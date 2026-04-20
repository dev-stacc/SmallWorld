{ config, pkgs, fontName, fontSize, ... } : {    
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