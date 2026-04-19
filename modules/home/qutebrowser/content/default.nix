{ config, lib, pkgs, ... } : let
    styles = import ./user_stylesheets.css { inherit config lib pkgs; };
in {
    content = lib.mkForce {
        autoplay = false;
        cookies.accept = "no-3rdparty";
        dns_prefetch = false;
        geolocation = false;
        canvas_reading = false;
        notifications.enabled = false;
        
        headers = {
            do_not_track = true;
            referer = "same-domain";
            user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36";
        };
        
        user_stylesheets = styles;
    };
}