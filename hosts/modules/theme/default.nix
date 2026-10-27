let
    borderWidth = 2;
in {
    window = {
        border = borderWidth;
        gapsIn = 6;
    };

    base16 = {
        base00 = "0e0202"; #main BACKGROUND
        base01 = "000000"; #BLACK

        base02 = "ff4050"; #main FOREGROUND
        base03 = "5ef6ff"; #secondary FOREGROUND
        base04 = "ffe44d"; #highlight FOREGROUND
        base05 = "ffffff"; #muted FOREGROUND
        base06 = "6abf24"; #special FOREGROUND

        base07 = "7a1f28"; #DARK RED
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
        customDir = ./fonts;

        monospace = "Neuromax Cool Futuristic Gaming Logo";
        sansSerif = "Neuromax Cool Futuristic Gaming Logo";
        serif     = "Neuromax Cool Futuristic Gaming Logo";
        readable  = "JetBrainsMono Nerd Font";

        sizes = {
            terminal      = 11;
            applications  = 11;
            desktop       = 11;
            popups        = 11;
            desktopGlyphs = 7;
        };
    };

    bar = {
        font     = "Departure Mono";
        fontSize = 10;
        width    = 18;
    };

    tabs = {
        width     = 15;
        gap       = borderWidth;
        margin    = 17;
        maxHeight = 210;
        slope     = 24;
        yOffset   = 0;
        fontSize  = 8;
        refreshMs = 150;
        inactiveOpacity = 0.6;
    };

    wallpaper = ./wallpapers/cyberpunk-bg.jpg;
}
