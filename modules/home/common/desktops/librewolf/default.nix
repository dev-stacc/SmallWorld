{ pkgs, lib, config, ... } : {
    imports = [ ./theme.nix ];

    programs.librewolf = {
        enable = true;

        nativeMessagingHosts = [ pkgs.tridactyl-native ];

        profiles.default = {
            isDefault = true;

            settings = {
                "browser.startup.page" = 1;
                "browser.startup.homepage" = "http://127.0.0.1:12345/homepage.html";
                "browser.newtab.url" = "http://127.0.0.1:12345/homepage.html";
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
