{ tailnet, ... } : {
    services.ntfy-sh = {
        enable = true;

        settings = {
            base-url = "https://ntfy.${tailnet.domain}";
            listen-http = "127.0.0.1:2586";
            behind-proxy = true;
            upstream-base-url = "https://ntfy.sh";
            cache-duration = "48h";
        };
    };

    biggerworld = {
        serve.services.ntfy."/" = "http://127.0.0.1:2586";
        notify.endpoint = "http://127.0.0.1:2586";
    };
}
