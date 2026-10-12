{ config, lib, pkgs, tailnet, theme, ... } :
let
    port = 9847;
    secretsFile = ../../../../../secrets/secrets.yaml;
    pageRefresh = 15;

    colors = theme.base16;

    colorNames = [
        "base00" "base01" "base02" "base03" "base04" "base05"
        "base06" "base07" "base08" "base09" "base0A" "base0B"
        "base0C" "base0D" "base0E" "base0F"
    ];

    themed = file: builtins.replaceStrings
        (map (n: "{{${n}}}") colorNames ++ [ "{{fontName}}" "{{fontSize}}" "{{refresh}}" ])
        (map (n: "#${colors.${n}}") colorNames ++ [
            theme.fonts.monospace
            (toString theme.fonts.sizes.applications)
            (toString pageRefresh)
        ])
        (builtins.readFile file);

    page = pkgs.writeText "flux-page.html" (themed ./files/flux.html);

    linksPage = pkgs.writeText "links-page.html" (themed ./files/links.html);

    backupsPage = pkgs.writeText "backups-page.html" (themed ./files/backups.html);

    classes = {
        asta      = "critical";
        aperture  = "critical";
        albireo   = "critical";
        argus     = "critical";
        amateus   = "critical";
        sanctuary = "critical";
        algol     = "watch";
        arcturus  = "watch";
        altair    = "watch";
        alula     = "ignore";
        atlas     = "ignore";
    };

    ports = {
        sanctuary = 80;
    };

    reachable = lib.filterAttrs
        (name: _: tailnet.ips.${name} != "PLACEHOLDER")
        classes;

    hosts = lib.mapAttrs (name: class: {
        ip = tailnet.ips.${name};
        class = class;
        port = ports.${name} or 22;
    }) reachable;

    clusterApp = auth: name: role: {
        inherit name auth role;
        url = "https://${name}.${tailnet.domain}/";
        label = "${name}.${tailnet.domain}";
        nav = true;
    };

    clusterApps = auth: roles: lib.mapAttrsToList (clusterApp auth) roles;

    hostPage = name: role: host: path: {
        inherit name role;
        auth = false;
        url = "https://${host}.${tailnet.domain}${path}";
        label = "${host}.${tailnet.domain}${lib.optionalString (path != "/") path}";
        nav = true;
        alert = false;
    };

    unguarded = clusterApps false {
        authentik = "login";
        vault = "secrets";
        nextcloud = "storage";
        search = "search";
    };

    hostPages = [
        (hostPage "flux" "fleet" "home" "/flux")
        (hostPage "backups" "-" "home" "/backups")
        (hostPage "pihole" "dns" "pihole" "/admin")
    ];

    guarded = clusterApps true {
        grafana = "metrics";
        jellyfin = "streaming";
        navidrome = "music";
        uptime = "status";
        sewing = "-";
        marketing = "-";
        wikipedia = "-";
        chat = "local ai";
    };

    hidden = [{
        name = "loki";
        url = "http://${tailnet.ips.loki}:3100/nginx-health";
        label = "loki.${tailnet.domain}:3100";
        role = "logs";
        auth = false;
        nav = false;
    }];

    targets = {
        inherit hosts;

        apps = unguarded ++ hostPages ++ guarded ++ hidden;

        suppressAlerts = [
            "Watchdog"
            "InfoInhibitor"
            "KubeSchedulerDown"
            "KubeControllerManagerDown"
            "KubeProxyDown"
        ];

        resticUnitQuery = "sum by (host, unit) "
            + ''(count_over_time({job="systemd-journal", unit=~"restic-.*"}[7d]))'';

        resticFailQuery = "sum by (host, unit) (count_over_time("
            + ''{job="systemd-journal", unit=~"restic-.*"}''
            + '' |~ "(?i)(fatal|error|failed|cannot|unable)"''
            + '' !~ "(?i)(no errors were found|0 errors)" [24h]))'';

        smartQuery = "sum by (host) (count_over_time("
            + ''{job="systemd-journal", unit="smartd.service"}''
            + " |~ \"(?i)(failed smart|failed attribute|below threshold"
            + "|unreadable \\\\(pending\\\\)|offline uncorrectable"
            + "|self-test log error|error count increased)\" [24h]))";

        expectedBackups = [
            {
                host = "albireo";
                paths = [
                    "/bigstorage/nextcloud/html"
                    "/bigstorage/nextcloud/dumps"
                    "/bigstorage/important"
                ];
            }
            {
                host = "asta";
                paths = [ "/var/lib/rancher/k3s/storage" "/var/lib/cluster-dumps" ];
            }
            {
                host = "aperture";
                paths = [ "/var/lib/rancher/k3s/storage" "/var/lib/cluster-dumps" ];
            }
            {
                host = "albireo";
                paths = [ "/var/lib/rancher/k3s/storage" "/var/lib/cluster-dumps" ];
            }
        ];

        backupStaleHours = 36;

        driftTimeout = 1200;
        historyDepth = 3;
        timelineDepth = 8;
    };
in {
    sops = {
        secrets = {
            grafana-api-token.sopsFile = secretsFile;
            ntfy-topic.sopsFile = secretsFile;
            ntfy-token.sopsFile = secretsFile;
            k3s-kubeconfig.sopsFile = secretsFile;
            restic-password.sopsFile = secretsFile;
            restic-amateus-repository.sopsFile = secretsFile;
        };

        templates."monitor.env" = {
            restartUnits = [ "monitor-poll.service" ];
            content = ''
                GRAFANA_TOKEN=${config.sops.placeholder.grafana-api-token}
                NTFY_TOPIC=${config.sops.placeholder.ntfy-topic}
                NTFY_TOKEN=${config.sops.placeholder.ntfy-token}
            '';
        };
    };

    systemd.services.monitor-poll = {
        description = "Fleet monitor collector";
        after = [ "network-online.target" "sops-nix.service" "tailscaled.service" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        path = with pkgs; [ kubectl restic ];

        environment = {
            MONITOR_PORT = toString port;
            MONITOR_TARGETS = builtins.toJSON targets;
            MONITOR_STATE_PATH = "/run/monitor/state.json";
            MONITOR_ALERT_PATH = "/run/monitor/alerts.json";
            MONITOR_PAGE = "${page}";
            MONITOR_LINKS_PAGE = "${linksPage}";
            MONITOR_BACKUPS_PAGE = "${backupsPage}";
            MONITOR_DEEP_LINK = "https://home.${tailnet.domain}/";
            NTFY_URL = "http://127.0.0.1:2586";
            NTFY_FALLBACK_URL = "https://ntfy.sh";
            MONITOR_BACKUPS_LINK = "https://home.${tailnet.domain}/backups";
            GRAFANA_URL = "https://grafana.${tailnet.domain}";
            LOKI_URL = "http://${tailnet.ips.loki}:3100";
        };

        serviceConfig = {
            ExecStart = "${pkgs.python3}/bin/python3 ${./files/monitor-poll.py}";
            EnvironmentFile = config.sops.templates."monitor.env".path;
            LoadCredential = [
                "kubeconfig:${config.sops.secrets.k3s-kubeconfig.path}"
                "loki-password:${config.sops.secrets.loki-push-password.path}"
                "restic-password:${config.sops.secrets.restic-password.path}"
                "restic-repository:${config.sops.secrets.restic-amateus-repository.path}"
            ];
            RuntimeDirectory = "monitor";
            RuntimeDirectoryMode = "0755";
            RuntimeDirectoryPreserve = "yes";
            Restart = "always";
            RestartSec = 10;
            DynamicUser = true;
            NoNewPrivileges = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
        };
    };
}
