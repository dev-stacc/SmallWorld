{ config, lib, pkgs, inputs, fontName, fontSize, ... } : let
    colors = config.stylix.base16Scheme;
    finalCss = (import ./generate-css.nix { inherit config lib pkgs fontName fontSize; }).cssPath;
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

        quickCss = lib.mkForce [ "${finalCss}" ];
    };
}
