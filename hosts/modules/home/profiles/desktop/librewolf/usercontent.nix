{ theme, tailnet, ... } : let
    template = builtins.readFile ./usercontent.css;

    userContent = builtins.replaceStrings
        [ "{{fontName}}" "{{tailnetDomain}}" ]
        [ theme.fonts.monospace tailnet.domain ]
        template;
in {
    programs.librewolf.profiles.default = {
        inherit userContent;

        settings = {
            "font.default.x-western" = "sans-serif";
            "font.name.sans-serif.x-western" = "DejaVu Sans";
            "font.name.serif.x-western" = "DejaVu Serif";
            "font.name.monospace.x-western" = "DejaVu Sans Mono";
        };
    };
}
