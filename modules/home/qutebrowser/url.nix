{ config, lib, pkgs, ... } : {
    url = {
        start_pages = [
            https://startpage.com
        ];
        searchegines = "https://www.startpage.com/sp/search?query={}";
    };
}
