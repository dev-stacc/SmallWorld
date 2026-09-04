{ pkgs, lib, config, ... } : {
    programs.librewolf = {
        enable = true;

        nativeMessagingHosts = [ pkgs.tridactyl-native ];

        profiles.default = {
            isDefault = true;

            settings = {
                "browser.startup.homepage" = "https://duckduckgo.com";
                "browser.newtabpage.enabled" = false;
            };

            search = {
                force = true;
                default = "DuckDuckGo";
                order = [ "DuckDuckGo" ];
            };

            extensions = {
                force = true;
                packages = [ pkgs.nur.repos.rycee.firefox-addons.tridactyl ];
            };
        };
    };

    home.file.".config/tridactyl/tridactylrc".text = ''
        " sensible defaults for a qutebrowser -> tridactyl switch
        set searchengine duckduckgo

        set editorcmd kitty -e nvim
        set yankto both
        set putfrom clipboard

        " don't nag about becoming the default browser / native messenger
        set nativemessenger true
    '';
}
