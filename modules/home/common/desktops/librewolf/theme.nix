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

    tridactylTheme = ":root{--tridactyl-cmdl-bg:#${colors.base00};--tridactyl-cmdl-fg:#${colors.base02};--tridactyl-cmplt-bg:#${colors.base00};--tridactyl-cmplt-fg:#${colors.base02};--tridactyl-header-first-bg:#${colors.base00};--tridactyl-header-second-bg:#${colors.base00};--tridactyl-header-third-bg:#${colors.base00};--tridactyl-of-bg:#${colors.base00};--tridactyl-of-fg:#${colors.base04};--tridactyl-url-fg:#${colors.base03};--tridactyl-url-bg:#${colors.base00};--tridactyl-status-bg:#${colors.base00};--tridactyl-status-fg:#${colors.base02};--tridactyl-status-border:1px solid #${colors.base00};}";

    homepage = pkgs.writeText "homepage.html" ''
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <title>homepage</title>
            <style>
                html, body {
                    height: 100%;
                    margin: 0;
                    background: #${colors.base00};
                    color: #${colors.base04};
                    font-family: "${fontName}", monospace;
                    font-size: ${toString fontSize}px;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                }
                .cmds {
                    color: #${colors.base05};
                }
                .cmds div {
                    margin: 0.2em 0;
                }
                .key {
                    color: #${colors.base02};
                    display: inline-block;
                    width: 8em;
                }
            </style>
        </head>
        <body>
            <div class="cmds">
                <div><span class="key">f</span>hint mode</div>
                <div><span class="key">d</span>close tab</div>
                <div><span class="key">u</span>undo close tab</div>
                <div><span class="key">gt / gT</span>next / prev tab</div>
                <div><span class="key">t</span>open in new tab</div>
                <div><span class="key">yy</span>yank url</div>
                <div><span class="key">:tabopen</span>scriptable new tab</div>
            </div>
        </body>
        </html>
    '';
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

    home.file.".local/share/librewolf/homepage.html".source = homepage;

    systemd.user.services.librewolf-homepage = {
        Unit = {
            Description = "Static server for LibreWolf custom homepage";
        };
        Service = {
            ExecStart = "${pkgs.darkhttpd}/bin/darkhttpd /home/anastasia/.local/share/librewolf --port 12345 --addr 127.0.0.1";
            Restart = "on-failure";
        };
        Install = {
            WantedBy = [ "default.target" ];
        };
    };

    programs.librewolf.profiles.default = {
        userChrome = builtins.readFile userChrome;

        settings = {
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            "browser.tabs.inTitlebar" = 1;
            "browser.toolbars.bookmarks.visibility" = "never";
        };
    };
}
