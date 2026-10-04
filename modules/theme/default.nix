# Single source of truth for colors, fonts and wallpaper.
# Plain data: no pkgs, no module system. Reaches desktop/WM hosts via
# specialArgs/extraSpecialArgs as `theme`; a TTY-only host never sees it.
{
    base16 = {
        base00 = "0e0202"; #main BACKGROUND
        base01 = "000000"; #BLACK

        base02 = "ff4050"; #main FOREGROUND
        base03 = "5ef6ff"; #secondary FOREGROUND
        base04 = "ffe44d"; #highlight FOREGROUND
        base05 = "ffffff"; #muted FOREGROUND
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
        monospace = "Major Mono Display";
        sansSerif = "Major Mono Display";
        serif     = "Major Mono Display";

        sizes = {
            terminal     = 11;
            applications = 11;
            desktop      = 11;
            popups       = 11;
        };
    };

    wallpaper = ./wallpapers/cyberpunk-bg.jpg;
}
