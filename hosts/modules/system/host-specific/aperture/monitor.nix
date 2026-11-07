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

    k8sPage = pkgs.writeText "k8s-page.html" (themed ./files/k8s.html);

    fleet = import ./fleet.nix { inherit lib tailnet; };

    targets = {
        hosts = fleet.hosts;

        apps = fleet.apps;

        suppressAlerts = [
            "Watchdog"
            "InfoInhibitor"
            "KubeSchedulerDown"
            "KubeControllerManagerDown"
            "KubeProxyDown"
            "KubeAPIErrorBudgetBurn"
        ];

        notifySeverities = [ "critical" "warning" ];

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

        expectedBackups = fleet.expectedBackups;

        backupStaleHours = fleet.backupStaleHours;

        driftTimeout = 1200;
        historyDepth = 3;
        timelineDepth = 8;
        restartThreshold = 10;
        eventDepth = 8;
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
        path = with pkgs; [ kubectl restic tailscale ];

        environment = {
            MONITOR_PORT = toString port;
            MONITOR_TARGETS = builtins.toJSON targets;
            MONITOR_STATE_PATH = "/run/monitor/state.json";
            MONITOR_ALERT_PATH = "/run/monitor/alerts.json";
            MONITOR_PAGE = "${page}";
            MONITOR_LINKS_PAGE = "${linksPage}";
            MONITOR_BACKUPS_PAGE = "${backupsPage}";
            MONITOR_K8S_PAGE = "${k8sPage}";
            MONITOR_DEEP_LINK = "https://home.${tailnet.domain}/";
            NTFY_URL = "http://127.0.0.1:2586";
            NTFY_FALLBACK_URL = "https://ntfy.sh";
            MONITOR_BACKUPS_LINK = "https://home.${tailnet.domain}/backups";
            MONITOR_K8S_LINK = "https://home.${tailnet.domain}/k8s";
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
