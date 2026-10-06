{ config, ... } : {
    services.sanoid = {
        enable = true;
        interval = "hourly";

        templates = {
            important = {
                hourly = 36;
                daily = 30;
                monthly = 12;
                yearly = 2;
                autosnap = true;
                autoprune = true;
            };

            # media-sync runs with --delete, so these snapshots are the only
            # thing making a deletion on asta recoverable
            mirror = {
                daily = 14;
                monthly = 2;
                autosnap = true;
                autoprune = true;
            };
        };

        datasets = {
            "bigstorage/nextcloud".useTemplate = [ "important" ];
            "bigstorage/important".useTemplate = [ "important" ];
            "bigstorage/media-backup".useTemplate = [ "mirror" ];
        };
    };

    services.syncoid = {
        enable = true;
        interval = "daily";
        commands = {
            "bigstorage/nextcloud".target = "smallstorage/backup/nextcloud";
            "bigstorage/important".target = "smallstorage/backup/important";
        };
    };

    sops.secrets = {
        restic-password = {
            sopsFile = ../../../../../secrets/secrets.yaml;
        };
        restic-amateus-repository = {
            sopsFile = ../../../../../secrets/secrets.yaml;
        };
    };

    services.restic.backups.amateus = {
        repositoryFile = config.sops.secrets.restic-amateus-repository.path;
        passwordFile = config.sops.secrets.restic-password.path;

        # first backup fails without this; the repo starts empty
        initialize = true;

        paths = [
            "/srv/nextcloud/html"
            "/srv/nextcloud/dumps"
            "/srv/important"
        ];

        exclude = [
            "/srv/nextcloud/html/data/*/cache"
            "/srv/nextcloud/html/data/appdata_*/preview"
        ];

        timerConfig = {
            OnCalendar = "daily";
            RandomizedDelaySec = "30m";
            Persistent = true;
        };

        # no pruneOpts: the server is --append-only, so forget must run there
    };
}
