{ config, lib, pkgs, fontName, ... } : let
    colors = config.lib.stylix.colors;

    colorNames = [
        "base00" "base01" "base02" "base03" "base04" "base05"
        "base06" "base07" "base08" "base09" "base0A" "base0B"
        "base0C" "base0D" "base0E" "base0F"
    ];

    template = builtins.readFile ./userchrome.css;

    userChrome = builtins.replaceStrings
        (map (n: "{{${n}}}") colorNames ++ [ "{{fontName}}" ])
        (map (n: "#${colors.${n}}") colorNames ++ [ fontName ])
        template;
in {
    programs.librewolf.profiles.default = {
        inherit userChrome;

        settings = {
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            "browser.tabs.inTitlebar" = 1;
            "browser.toolbars.bookmarks.visibility" = "never";
        };
    };
}
