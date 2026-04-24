{ config, lib, pkgs, ... } : let 
    colors = config.stylix.base16Scheme;
    
    template = builtins.readFile ./colors.lua;
    
    result = lib.foldl' (acc: name: 
        builtins.replaceStrings 
            ["stylix.${name}"]
            ["#${colors.${name}}"]
            acc
    ) template [
        "base00" "base01" "base02" "base03" "base04" "base05"
        "base06" "base07" "base08" "base09" "base0A" "base0B"
        "base0C" "base0D" "base0E" "base0F"
    ];
in {
    extraConfigLua = result;
}
