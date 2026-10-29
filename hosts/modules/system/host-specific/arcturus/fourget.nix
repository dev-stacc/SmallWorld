{ config, pkgs, lib, theme, ... } : let
    port = 12346;
    stateDir = "/var/lib/fourget";

    root = import ../../../../../k8s/apps/fourget/root.nix {
        inherit pkgs lib theme;
    };

    fastcgi = ''
        include ${config.services.nginx.package}/conf/fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT $document_root;
        fastcgi_pass unix:${config.services.phpfpm.pools.fourget.socket};
        fastcgi_intercept_errors on;
    '';

    php = pkgs.php84.buildEnv {
        extensions = { all, enabled } : enabled ++ (with all; [ apcu imagick sodium ]);

        extraConfig = ''
            display_errors = Off
            error_reporting = E_ALL & ~E_DEPRECATED
            memory_limit = 256M
            max_execution_time = 60
        '';
    };
in {
    users.users.fourget = {
        isSystemUser = true;
        group = "fourget";
    };

    users.groups.fourget = { };

    systemd.services.fourget-init = {
        wantedBy = [ "multi-user.target" ];
        before = [ "phpfpm-fourget.service" ];
        requiredBy = [ "phpfpm-fourget.service" ];

        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
        };

        script = ''
            rm -rf ${stateDir}
            mkdir -p ${stateDir}
            cp -a ${root}/. ${stateDir}/
            chmod -R u+w ${stateDir}
            mkdir -p ${stateDir}/icons
            chown -R fourget:fourget ${stateDir}
        '';
    };

    services.phpfpm.pools.fourget = {
        user = "fourget";
        group = "fourget";
        phpPackage = php;

        settings = {
            "listen.owner" = config.services.nginx.user;
            "listen.group" = config.services.nginx.group;
            "pm" = "dynamic";
            "pm.max_children" = 16;
            "pm.start_servers" = 2;
            "pm.min_spare_servers" = 2;
            "pm.max_spare_servers" = 4;
            "pm.max_requests" = 500;
            "php_admin_flag[display_errors]" = "off";
        };
    };

    services.nginx = {
        enable = true;

        virtualHosts.fourget = {
            listen = [ { addr = "127.0.0.1"; inherit port; } ];
            root = stateDir;

            locations = {
                "/".tryFiles = "$uri @php";

                "@php".extraConfig = ''
                    try_files $uri.php $uri/index.php =404;
                    ${fastcgi}
                '';

                "~ \\.php$".extraConfig = fastcgi;

                "^~ /data".extraConfig = "return 404;";
            };
        };
    };
}
