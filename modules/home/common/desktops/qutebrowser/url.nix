{ config, lib, pkgs, ... } : {
    url = {
        start_pages = [
            "https://startpage.com"
        ];
        searchengines = {
            DEFAULT = "https://www.startpage.com/sp/search?query={}";
        };
    };
}
