{ tailnet, ... } : {
    programs.librewolf.profiles.default.bookmarks = {
        force = true;

        settings = [
            {
                name = "home";
                keyword = "h";
                url = "https://home.${tailnet.domain}";
            }
            {
                name = "tailscale";
                keyword = "ts";
                url = "https://login.tailscale.com/admin/machines";
            }
            {
                name = "github";
                keyword = "gh";
                url = "https://github.com";
            }
            {
                name = "ÉTS Portal";
                keyword = "ets";
                url = "https://portail.etsmtl.ca/";
            }
        ];
    };
}
