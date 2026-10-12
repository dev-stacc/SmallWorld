{ config, lib, ... } :
let
    active = config.services.k3s.enable && config.biggerworld.secrets.enable;

    storage = "/var/lib/rancher/k3s/storage";
    dumps = "/var/lib/cluster-dumps";

    exclude = [
        "${storage}/*_monitoring_prometheus-*-prometheus-db-*"
        "${storage}/*_monitoring_alertmanager-*-alertmanager-db-*"
        "${storage}/*_monitoring_storage-loki-*"
        "${storage}/*_monitoring_storage-tempo-*"
        "${storage}/*_kiwix_kiwix-data"
        "${storage}/*_jellyfin_jellyfin-config/cache"
        "${storage}/*_jellyfin_jellyfin-config/transcodes"
    ];
in {
    sops.secrets = lib.mkIf active {
        restic-password = {
            sopsFile = ../../../../../secrets/secrets.yaml;
        };
        restic-amateus-repository = {
            sopsFile = ../../../../../secrets/secrets.yaml;
        };
    };

    systemd.tmpfiles.rules = lib.mkIf active [
        "d ${storage}          0700 root root -"
        "d ${dumps}            0750 root root -"
        "d ${dumps}/k3s        0750 root root -"
        "d ${dumps}/authentik  0750 999  999  -"
        "d ${dumps}/prose      0750 999  999  -"
    ];

    services.restic.backups = lib.mkIf active {
        cluster = {
            repositoryFile = config.sops.secrets.restic-amateus-repository.path;
            passwordFile = config.sops.secrets.restic-password.path;
            initialize = true;
            paths = [ storage dumps ];
            inherit exclude;

            timerConfig = {
                OnCalendar = "01:30";
                RandomizedDelaySec = "30m";
                Persistent = true;
            };
        };
    };
}
