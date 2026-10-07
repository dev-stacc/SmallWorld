{ config, pkgs, ... } :
let
    repo = "/srv/restic";

    env = [
        "RESTIC_REPOSITORY=${repo}"
        "RESTIC_PASSWORD_FILE=${config.sops.secrets.restic-password.path}"
        "RESTIC_CACHE_DIR=/var/cache/restic"
    ];

    verify = pkgs.writeShellScript "restic-verify" ''
        set -euo pipefail
        restic=${pkgs.restic}/bin/restic

        $restic check --read-data-subset=5%

        target=$($restic ls --long latest 2>/dev/null \
            | awk '$1 ~ /^-/ && $4 + 0 > 0 && !found { print $NF; found = 1 }')

        if [ -z "$target" ]; then
            echo "no regular file found in the latest snapshot"
            exit 1
        fi

        bytes=$($restic dump latest "$target" | wc -c)
        if [ "$bytes" -le 0 ]; then
            echo "restore smoke test produced no data for $target"
            exit 1
        fi

        echo "restored $bytes bytes from $target"
    '';
in {
    sops.secrets.restic-password = {
        sopsFile = ../../../../../secrets/secrets.yaml;
        owner = "restic";
        mode = "0400";
    };

    systemd.services = {
        restic-retention = {
            description = "Prune the append-only restic repository";
            after = [ "restic-rest-server.service" ];
            serviceConfig = {
                Type = "oneshot";
                User = "restic";
                Group = "restic";
                CacheDirectory = "restic";
                Environment = env;
                ExecStart = "${pkgs.restic}/bin/restic forget --prune "
                    + "--keep-daily 14 --keep-weekly 8 --keep-monthly 12";
            };
        };

        restic-verify = {
            description = "Verify restic repository integrity and restorability";
            after = [ "restic-rest-server.service" ];
            serviceConfig = {
                Type = "oneshot";
                User = "restic";
                Group = "restic";
                CacheDirectory = "restic";
                Environment = env;
                ExecStart = verify;
            };
        };
    };

    systemd.timers = {
        restic-retention = {
            wantedBy = [ "timers.target" ];
            timerConfig = {
                OnCalendar = "05:00";
                RandomizedDelaySec = "30m";
                Persistent = true;
            };
        };

        restic-verify = {
            wantedBy = [ "timers.target" ];
            timerConfig = {
                OnCalendar = "Sun 06:00";
                RandomizedDelaySec = "30m";
                Persistent = true;
            };
        };
    };
}
