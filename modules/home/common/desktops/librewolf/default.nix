{ pkgs, lib, config, ... } : {
    imports = [ ./theme.nix ];

    programs.librewolf = {
        enable = true;

        nativeMessagingHosts = [ pkgs.tridactyl-native ];

        profiles.default = {
            isDefault = true;

            settings = {
                "browser.startup.homepage" = "https://duckduckgo.com";
                "browser.newtabpage.enabled" = false;
                "privacy.resistFingerprinting.letterboxing" = true;
            };

            search = {
                force = true;
                default = "ddg";
                order = [ "ddg" ];
            };

            extensions = {
                force = true;
                packages = [ pkgs.nur.repos.rycee.firefox-addons.tridactyl ];
            };
        };
    };

}
