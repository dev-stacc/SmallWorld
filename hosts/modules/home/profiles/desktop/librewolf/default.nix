{ pkgs, ... } : {
    imports = [ ./userchrome.nix ./tridactyl.nix ./homepage.nix ./privacy.nix ./ephemeral.nix ];

    programs.librewolf = {
        enable = true;

        nativeMessagingHosts = [ pkgs.tridactyl-native ];

        policies.SearchEngines = {
            Add = [{
                Name = "searxng";
                URLTemplate = "http://127.0.0.1:12345/search.html?q={searchTerms}";
                Alias = "s";
                Method = "GET";
            }];
            Default = "searxng";
        };

        profiles.default = {
            isDefault = true;

            settings = {
                "browser.startup.page" = 1;
                "browser.startup.homepage" = "http://127.0.0.1:12345/homepage.html";
                "browser.newtab.url" = "http://127.0.0.1:12345/homepage.html";
                "browser.newtabpage.enabled" = false;
                "privacy.resistFingerprinting.letterboxing" = true;
                "extensions.autoDisableScopes" = 0;
            };

            extensions = {
                force = true;
                packages = [
                    pkgs.nur.repos.rycee.firefox-addons.tridactyl
                    pkgs.nur.repos.rycee.firefox-addons.ublock-origin
                ];
            };
        };
    };

}
