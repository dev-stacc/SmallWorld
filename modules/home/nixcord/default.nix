{ config, lib, pkgs, inputs, fontName, fontSize, ... } : let
    colors = config.stylix.base16Scheme;
    customVesktop = pkgs.symlinkJoin {
        name = "vesktop";
        paths = [ (pkgs.vesktop.override { withSystemVencord = false; }) ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
            wrapProgram $out/bin/vesktop \
                --add-flags "--enable-features=WebRTCPipeWireCapturer --ozone-platform=wayland"
        '';
    };
in {
    home.packages = [ customVesktop ];

    xdg.desktopEntries.vesktop = {
        name = "Vesktop";
        exec = "vesktop --enable-features=WebRTCPipeWireCapturer --ozone-platform=wayland %U";
        icon = "vesktop";
        terminal = false;
        categories = [ "Network" "InstantMessaging" ];
        mimeType = [ "x-scheme-handler/discord" ];
    };

    programs.nixcord = {
        enable = true;
        vesktop.enable = false;
        discord.enable = false;

        vesktopConfig = {
            useQuickCss = true;
            customTitleBar = false;
            minimizeToTray = false;
            tray = false;
            hardwareAcceleration = true;
            hardwareVideoAcceleration = false;
            disableSmoothScroll = true;
            openLinksWithElectron = false;
            checkUpdates = false;
            enableSplashScreen = false;
            discordBranch = "stable";
            transparent = true;
        };
        
        config = {
            transparent = true;
            enableReactDevtools = true;
            plugins = {
                noDevtoolsWarning.enable = true;
                noReplyMention.enable = true;
                messageLogger.enable = false;

                readAllNotificationsButton.enable = true;
                showHiddenChannels.enable = true;
                friendInvites.enable = true;
                webScreenShareFixes.enable = false;
            };
        };

        quickCss = ''
            * {
                background: none !important;
                background-color: transparent !important;
                shadow: none !important;
                outline: none !important;
                font-family: "${fontName}" !important;
                color: #${colors.base02} !important;
                border-radius: 0 !important;
                border-color: #${colors.base02} !important;
            }
            .form_f75fb0 {
                margin-top: 0 !important;
                padding: 0 !important;
            }

            [class*="popoutContainer"],
            [id*="popout"],
            [class*="drawerSizingWrapper"],
            [class*="modal"],
            .container__8a031{
                border: none !important;
                background: #${colors.base00} !important;
            }

            .bar__3b95d {
                background: #${colors.base00} !important;
            }

            [class*="radient"] {
                background: unset !important;
            }

            .channelTextArea_f75fb0 {
                margin-right: 6px;
                margin-left: 6px;
                border: none !important;
            }

            .panels__5e434,
            .wrapper_e131a9 {
                margin-left: 3px;
                border: none !important;
                border-left: 6px solid #${colors.base04} !important;
            }

            .container__37e49 {
                margin-left: 0px !important;
                margin-right: 6px !important;
                margin-top: 0px !important;
                border-width: 2px !important;
                corner-shape: bevel !important;
                border-bottom-right-radius: 18px !important;
                background: #${colors.base00} !important;
                background-color: #${colors.base00} !important;
            }
        '';
    };
}
