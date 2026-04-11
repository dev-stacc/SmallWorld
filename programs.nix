{config, lib, pkgs, ...}:
{
 programs = {
  qutebrowser = {
    enable = true;
  };

  fzf = {
   enable = true;
   enableBashIntegration = true;
  };

  git = {
   enable = true;
   settings = {
    user = {
     name = "Anastasia";
     email = "89532616+dev-stacc@users.noreply.github.com";
    };
   };
   extraConfig = {
    credential.helper = "store --file /home/anastasia/.git-credentials";
   };
  };

  fresh-editor = {
   enable = true;
  };

  vesktop = {
   enable = true;
   package = pkgs.vesktop;
   settings = {
    appBadge = false;
    arRPC = true;
    checkUpdates = false;
    customTitleBar = false;
    disableMinSize = true;
    minimizeToTray = false;
    tray = false;
    splashBackground = "#000000";
    splashColor = "#ffffff";
    splashTheming = true;
    staticTitle = true;
    hardwareAcceleration = true;
    discordBranch = "stable";
   };
  };
 };
}
