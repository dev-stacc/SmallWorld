{ pkgs, lib, theme, searxng } : let
    colors = theme.base16;

    names = [ "base00" "base01" "base02" "base03" "base04" "base05" "base06" ];

    css = pkgs.writeText "searxng.css" (builtins.replaceStrings
        (map (n: "\${${lib.toUpper n}}") names ++ [ "\${FONT_NAME}" ])
        (map (n: "#${colors.${n}}") names ++ [ theme.fonts.monospace ])
        (builtins.readFile ./searxng.css));
in pkgs.runCommand "searxng-static-themed" { } ''
    cp -aL ${searxng}/share/static $out
    chmod -R u+w $out
    for f in sxng-ltr sxng-rtl; do
        cat ${css} >> $out/themes/simple/$f.min.css
        gzip -9c $out/themes/simple/$f.min.css > $out/themes/simple/$f.min.css.gz
        rm -f $out/themes/simple/$f.min.css.br
    done
''
