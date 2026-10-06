{ config, ... } :
let
    paths = [
        "/bigstorage/nextcloud/html"
        "/bigstorage/nextcloud/dumps"
        "/bigstorage/important"
    ];

    exclude = [
        "/bigstorage/nextcloud/html/data/*/cache"
        "/bigstorage/nextcloud/html/data/appdata_*/preview"
    ];
in {
    sops.secrets = {
        restic-password = {
            sopsFile = ../../../../../secrets/secrets.yaml;
        };
        restic-amateus-repository = {
            sopsFile = ../../../../../secrets/secrets.yaml;
        };
    };

    services.restic.backups = {
        smallstorage = {
            repository = "/smallstorage/backup";
            passwordFile = config.sops.secrets.restic-password.path;
            initialize = true;
            inherit paths exclude;

            timerConfig = {
                OnCalendar = "daily";
                Persistent = true;
            };

            pruneOpts = [
                "--keep-daily 14"
                "--keep-weekly 8"
                "--keep-monthly 12"
            ];
        };

        amateus = {
            repositoryFile = config.sops.secrets.restic-amateus-repository.path;
            passwordFile = config.sops.secrets.restic-password.path;
            initialize = true;
            inherit paths exclude;

            timerConfig = {
                OnCalendar = "daily";
                RandomizedDelaySec = "30m";
                Persistent = true;
            };
        };
    };
}
