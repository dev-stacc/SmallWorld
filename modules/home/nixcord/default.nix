{ config, lib, pkgs, inputs, ... }:

let
    colors = config.stylix.base16Scheme;
in {
    imports = [ inputs.nixcord.homeManagerModules.nixcord ];
    
    programs.nixcord = {
        enable = true;
        vesktop.enable = true;
        
        vesktopConfig = {
            transparent = true;
            customTitleBar = false;
            minimizeToTray = false;
            tray = false;
            hardwareAcceleration = true;
            disableSmoothScroll = true;
            openLinksWithElectron = false;
            checkUpdates = false;
            enableSplashScreen = false;
            discordBranch = "stable";
        };
        
        config = {
            useQuickCss = true;
        
            plugins = {
                noDevtoolsWarning.enable = true;
                noReplyMention.enable = true;
                messageLogger.enable = true;
                
                transparent.enable = true;
                
                readAllNotificationsButton.enable = true;
                showHiddenChannels.enable = true;
                friendInvites.enable = true;
            };
        };
        
        quickCss = ''
            :root {
                --bg-primary: #${colors.base00};
                --bg-secondary: #${colors.base01};
                --text-normal: #${colors.base02};
                --text-muted: #${colors.base05};
                --brand-experiment: #${colors.base0D};
            }
            
            .app-2rEoOp {
                background: transparent !important;
            }
        '';
    };
}
