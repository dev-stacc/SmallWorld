{ pkgs, theme, ... } :
let
    fontTools = pkgs.python3.withPackages (ps: [ ps.fonttools ]);

    customFonts = pkgs.runCommandLocal "theme-fonts" {
        nativeBuildInputs = [ fontTools ];
    } ''
        mkdir -p $out/share/fonts/theme
        for face in ${theme.fonts.customDir}/*; do
            python3 ${./monospace.py} "$face" "$out/share/fonts/theme/$(basename "$face")"
        done
        chmod 444 $out/share/fonts/theme/*
    '';
in {
    home.packages = [ customFonts ] ++ (with pkgs; [
        departure-mono
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
