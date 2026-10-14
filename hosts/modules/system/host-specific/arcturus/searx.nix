{ config, lib, pkgs, theme, ... } : let
    colors = theme.base16;

    names = [ "base00" "base01" "base02" "base03" "base04" "base05" "base06" ];

    css = pkgs.writeText "searxng.css" (builtins.replaceStrings
        (map (n: "\${${lib.toUpper n}}") names ++ [ "\${FONT_NAME}" ])
        (map (n: "#${colors.${n}}") names ++ [ theme.fonts.monospace ])
        (builtins.readFile ../../../../../k8s/apps/searxng/searxng.css));

    static = pkgs.runCommand "searxng-static-themed" { } ''
        cp -aL ${config.services.searx.package}/share/static $out
        chmod -R u+w $out
        for f in sxng-ltr sxng-rtl; do
            cat ${css} >> $out/themes/simple/$f.min.css
            gzip -9c $out/themes/simple/$f.min.css > $out/themes/simple/$f.min.css.gz
        done
    '';
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
