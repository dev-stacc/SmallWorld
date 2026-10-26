{ pkgs, theme, ... } :
let
    customFonts = pkgs.runCommandLocal "theme-fonts" { } ''
        install -Dm444 -t $out/share/fonts/theme ${theme.fonts.customDir}/*
    '';
in {
    home.packages = [ customFonts ] ++ (with pkgs; [
        major-mono-display
        nerd-fonts.jetbrains-mono
        dejavu_fonts
        liberation_ttf
        noto-fonts-color-emoji
    ]);

    fonts.fontconfig = {
        enable = true;

        defaultFonts = {
            monospace = [ theme.fonts.monospace "JetBrainsMono Nerd Font" ];
            sansSerif = [ theme.fonts.sansSerif "DejaVu Sans" ];
            serif = [ theme.fonts.serif "DejaVu Serif" ];
            emoji = [ "Noto Color Emoji" ];
        };

        hinting = "none";
        antialiasing = false;
    };
}
