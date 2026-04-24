{ config, lib, pkgs, inputs, fontName, fontSize, ... } : let
    colors = config.stylix.base16Scheme;
in {
    programs.nixcord = {
        enable = true;
        vesktop.enable = true;
        discord.enable = false;

        vesktopConfig = {
            useQuickCss = true;
            customTitleBar = false;
            minimizeToTray = false;
            tray = false;
            hardwareAcceleration = true;
            disableSmoothScroll = true;
            openLinksWithElectron = false;
            checkUpdates = false;
            enableSplashScreen = false;
            discordBranch = "stable";
            transparent = true;
        };
        
        config = {
            transparent = true;
            plugins = {
                noDevtoolsWarning.enable = true;
                noReplyMention.enable = true;
                messageLogger.enable = false;

                readAllNotificationsButton.enable = true;
                showHiddenChannels.enable = true;
                friendInvites.enable = true;
            };
        };

        quickCss = ''
            * {
                background: none !importat;
                background-color: transparent !important;
                shadow: none !important;
                outline: none !important;
                font-family: "${fontName}" !important;
                color: #${colors.base02} !important;
                border-radius: 0 !important;
                border-color: #${colors.base02} !important;
            }
            
            [class*="popout_"] {
                background-color: #${colors.base02} !important;
            }
        '';
    };
}
