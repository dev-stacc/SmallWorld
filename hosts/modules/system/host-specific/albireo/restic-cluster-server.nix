{ config, pkgs, tailnet, ... } :
let
    repo = "/smallstorage/cluster";

    env = [
        "RESTIC_REPOSITORY=${repo}"
        "RESTIC_PASSWORD_FILE=${config.sops.secrets.restic-password.path}"
        "RESTIC_CACHE_DIR=/var/cache/restic"
    ];

    verify = pkgs.writeShellScript "restic-cluster-verify" ''
        set -euo pipefail
        restic=${pkgs.restic}/bin/restic
        awk=${pkgs.gawk}/bin/awk

        $restic check --read-data-subset=5%

        target=$($restic ls --long latest 2>/dev/null \
            | $awk '$1 ~ /^-/ && $4 + 0 > 0 && !found { print $NF; found = 1 }')

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
    sops.secrets = {
        restic-cluster-htpasswd = {
            sopsFile = ../../../../../secrets/secrets.yaml;
            owner = "restic";
            mode = "0400";
        };

        restic-password = {
            sopsFile = ../../../../../secrets/secrets.yaml;
            owner = "restic";
            mode = "0400";
        };
    };

    services.restic.server = {
        enable = true;
        dataDir = repo;

        # appendOnly means the k3s servers cannot run `restic forget --prune`;
        # retention has to be driven from here, as on amateus
        appendOnly = true;
        htpasswd-file = config.sops.secrets.restic-cluster-htpasswd.path;

        # a bare port would listen on every interface; the module asserts
        # against a leading ":" because it uses socket activation
        listenAddress = "${tailnet.ips.albireo}:8000";
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 8000 ];

    systemd.services = {
        restic-cluster-retention = {
            description = "Prune the append-only cluster restic repository";
            after = [ "restic-rest-server.service" ];
            serviceConfig = {
                Type = "oneshot";
                User = "restic";
                Group = "restic";
                CacheDirectory = "restic";
                Environment = env;
                ExecStart = "${pkgs.restic}/bin/restic forget --prune "
                    + "--retry-lock 30m "
                    + "--keep-daily 14 --keep-weekly 8 --keep-monthly 12";
            };
        };

        restic-cluster-verify = {
            description = "Verify cluster restic repository integrity and restorability";
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
        restic-cluster-retention = {
            wantedBy = [ "timers.target" ];
            timerConfig = {
                OnCalendar = "05:30";
                RandomizedDelaySec = "30m";
                Persistent = true;
            };
        };

        restic-cluster-verify = {
            wantedBy = [ "timers.target" ];
            timerConfig = {
                OnCalendar = "Sun 07:00";
                RandomizedDelaySec = "30m";
                Persistent = true;
            };
        };
    };
}
