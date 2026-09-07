{ config, lib, pkgs, ... } : let
    colors = config.lib.stylix.colors;

    tridactylVars = {
        "tridactyl-cmdl-bg" = colors.base00;
        "tridactyl-cmdl-fg" = colors.base02;
        "tridactyl-cmplt-bg" = colors.base00;
        "tridactyl-cmplt-fg" = colors.base02;
        "tridactyl-header-first-bg" = colors.base00;
        "tridactyl-header-second-bg" = colors.base00;
        "tridactyl-header-third-bg" = colors.base00;
        "tridactyl-of-bg" = colors.base00;
        "tridactyl-of-fg" = colors.base04;
        "tridactyl-url-fg" = colors.base03;
        "tridactyl-url-bg" = colors.base00;
        "tridactyl-status-bg" = colors.base00;
        "tridactyl-status-fg" = colors.base02;
    };

    tridactylDecls = lib.concatStringsSep ";" (
        lib.mapAttrsToList (name: value: "--${name}:#${value}") tridactylVars
    );

    tridactylTheme = ":root{${tridactylDecls};--tridactyl-status-border:1px solid #${colors.base00};}";
in {
    home.file.".config/tridactyl/tridactylrc".text = ''
        " sensible defaults for a qutebrowser -> tridactyl switch
        set searchengine duckduckgo

        set editorcmd kitty -e nvim
        set yankto both
        set putfrom clipboard

        " don't nag about becoming the default browser / native messenger
        set nativemessenger true

        set newtab http://127.0.0.1:12345/homepage.html

        " command line / completions bg matches the tab bar (no native messenger needed)
        set customthemes.stylix ${tridactylTheme}
        set theme stylix
    '';
}
