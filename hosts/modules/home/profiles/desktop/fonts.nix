{ pkgs, lib, theme, ... } :
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

        configFile.prompt-font = {
            enable = true;
            priority = 60;
            text = ''
                <?xml version="1.0"?>
                <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
                <fontconfig>
                  <match target="scan">
                    <test name="family"><string>${theme.fonts.promptFamily}</string></test>
                    <edit name="spacing"><int>100</int></edit>
                  </match>
                  <match target="pattern">
                    <test name="family"><string>${theme.fonts.promptFamily}</string></test>
                    <edit name="slant" mode="assign"><const>roman</const></edit>
                  </match>
                </fontconfig>
            '';
        };
    };

    home.activation.themeFontCache = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${lib.getBin pkgs.fontconfig}/bin/fc-cache -f
    '';
}
