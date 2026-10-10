{ config, lib, pkgs, tailnet, ... } :
let
    port = 9847;
    secretsFile = ../../../../../secrets/secrets.yaml;

    classes = {
        asta      = "critical";
        aperture  = "critical";
        albireo   = "critical";
        argus     = "critical";
        amateus   = "critical";
        algol     = "watch";
        arcturus  = "watch";
        altair    = "watch";
        sanctuary = "watch";
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

    app = name: {
        inherit name;
        url = "https://${name}.${tailnet.domain}/";
    };

    targets = {
        inherit hosts;

        apps = map app [
            "vault"
            "nextcloud"
            "jellyfin"
            "navidrome"
            "grafana"
            "uptime"
            "sewing"
            "marketing"
            "wikipedia"
            "chat"
            "authentik"
        ] ++ [{
            name = "loki";
            url = "http://${tailnet.ips.loki}:3100/nginx-health";
        }];

        suppressAlerts = [
            "Watchdog"
            "InfoInhibitor"
            "KubeSchedulerDown"
            "KubeControllerManagerDown"
            "KubeProxyDown"
        ];

        resticUnitQuery = "sum by (host, unit) "
            + ''(count_over_time({job="systemd-journal", unit=~"restic-.*"}[7d]))'';
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

        templates."monitor.env".content = ''
            GRAFANA_TOKEN=${config.sops.placeholder.grafana-api-token}
            NTFY_TOPIC=${config.sops.placeholder.ntfy-topic}
            NTFY_TOKEN=${config.sops.placeholder.ntfy-token}
        '';
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
            MONITOR_DEEP_LINK = "https://grafana.${tailnet.domain}/";
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
