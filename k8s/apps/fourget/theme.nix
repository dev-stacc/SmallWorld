{ pkgs, lib, theme } : let
    colors = theme.base16;

    names = [ "base00" "base01" "base02" "base03" "base04" "base05" "base06" ];
in pkgs.writeText "biggerworld.css" (builtins.replaceStrings
    (map (n: "\${${lib.toUpper n}}") names ++ [ "\${FONT_NAME}" ])
    (map (n: "#${colors.${n}}") names ++ [ theme.fonts.monospace ])
    (builtins.readFile ./fourget.css))
