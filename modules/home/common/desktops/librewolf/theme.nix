{ config, lib, pkgs, fontName, fontSize, ... } : let
    colors = config.lib.stylix.colors;

    userChrome = pkgs.writeText "userChrome.css" ''
        :root {
            --base00: #${colors.base00};
            --base01: #${colors.base01};
            --base02: #${colors.base02};
            --base03: #${colors.base03};
            --base04: #${colors.base04};
            --base05: #${colors.base05};
            --tab-min-height: 22px;
        }

        :root, #titlebar, #nav-bar, #TabsToolbar, #PersonalToolbar, #navigator-toolbox, toolbar {
            background: var(--base00) !important;
            color: var(--base02) !important;
            border: none !important;
            box-shadow: none !important;
        }

        #tabbrowser-tabs, .tabbrowser-tab, .toolbarbutton-text, #urlbar, #urlbar-input {
            font-family: "${fontName}", monospace !important;
            color: var(--base02) !important;
        }

        .tab-background {
            background: var(--base00) !important;
        }

        .tab-background[selected] {
            background: var(--base00) !important;
        }

        .tabbrowser-tab .tab-label {
            color: var(--base05) !important;
        }

        .tabbrowser-tab[selected] .tab-label {
            color: var(--base02) !important;
        }

        #TabsToolbar {
            padding-block: 0 !important;
        }

        .tab-content {
            padding-block: 0 !important;
        }

        .tab-icon-image,
        .tab-throbber,
        .tab-icon-overlay,
        .tab-icon-sound {
            display: none !important;
        }

        #urlbar-background {
            background: var(--base00) !important;
            border: 1px solid var(--base02) !important;
        }

        #nav-bar, #PersonalToolbar {
            display: none !important;
        }

        #navigator-toolbox::after {
            border: none !important;
            box-shadow: none !important;
            background: none !important;
        }

        #appcontent, #browser, #tabbrowser-tabpanels {
            background: var(--base00) !important;
        }

        .browserContainer, .browserSidebarContainer {
            background-color: inherit !important;
        }

        #tabbrowser-tabpanels {
            margin-top: 24px !important;
        }
    '';

    tridactylTheme = ":root{--tridactyl-cmdl-bg:#${colors.base00};--tridactyl-cmdl-fg:#${colors.base02};--tridactyl-cmplt-bg:#${colors.base00};--tridactyl-cmplt-fg:#${colors.base02};--tridactyl-header-first-bg:#${colors.base00};--tridactyl-header-second-bg:#${colors.base00};--tridactyl-header-third-bg:#${colors.base00};--tridactyl-of-bg:#${colors.base00};--tridactyl-of-fg:#${colors.base04};--tridactyl-url-fg:#${colors.base03};--tridactyl-url-bg:#${colors.base00};}";
in {
    home.file.".config/tridactyl/tridactylrc".text = ''
        " sensible defaults for a qutebrowser -> tridactyl switch
        set searchengine duckduckgo

        set editorcmd kitty -e nvim
        set yankto both
        set putfrom clipboard

        " don't nag about becoming the default browser / native messenger
        set nativemessenger true

        " command line / completions bg matches the tab bar (no native messenger needed)
        set customthemes.stylix ${tridactylTheme}
        set theme stylix
    '';

    programs.librewolf.profiles.default = {
        userChrome = builtins.readFile userChrome;

        settings = {
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            "browser.tabs.inTitlebar" = 1;
            "browser.toolbars.bookmarks.visibility" = "never";
        };
    };
}
