{ lib, theme, ... } : let
    colors = theme.base16;

    template = builtins.readFile ./colors.lua;
    autopairs = builtins.readFile ./autopairs.lua;

    result = lib.foldl' (acc: name:
        builtins.replaceStrings
            ["theme.${name}"]
            ["#${colors.${name}}"]
            acc
    ) template [
        "base00" "base01" "base02" "base03" "base04" "base05"
        "base06" "base07" "base08" "base09" "base0A" "base0B"
        "base0C" "base0D" "base0E" "base0F"
    ];
in {
    extraConfigLua = result + "\n" + autopairs;
}
