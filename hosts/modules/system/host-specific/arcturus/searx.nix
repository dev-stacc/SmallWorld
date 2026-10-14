{ config, lib, pkgs, theme, ... } : let
    static = import ../../../../../k8s/apps/searxng/static.nix {
        inherit pkgs lib theme;
        searxng = config.services.searx.package;
    };
in {
    sops = {
        secrets.searx-secret.sopsFile = ../../../../../secrets/secrets.yaml;

        templates."searx.env" = {
            restartUnits = [ "searx-init.service" "searx.service" ];
            content = ''
                SEARXNG_SECRET=${config.sops.placeholder.searx-secret}
            '';
        };
    };

    services.searx = {
        enable = true;
        environmentFile = config.sops.templates."searx.env".path;

        settings = {
            general.instance_name = "local";

            server = {
                port = 12346;
                bind_address = "127.0.0.1";
                secret_key = "$SEARXNG_SECRET";
                limiter = false;
                public_instance = false;
                image_proxy = false;
            };

            search = {
                formats = [ "html" "json" ];
                autocomplete = "duckduckgo";
            };

            ui = {
                query_in_title = true;
                static_path = "${static}";
                theme_args.simple_style = "dark";
                hotkeys = "vim";
                center_alignment = true;
            };
        };
    };
}
