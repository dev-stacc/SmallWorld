{ config, lib, pkgs, ... } : {
    url = {
        start_pages = [
            https://startpage.com
        ];
        searchengines = "https://www.startpage.com/sp/search?query={}";
    };
}
