{ config, pkgs, tailnet, username, ... } : {
    sops.secrets.albireo-media-sync-key = {
        sopsFile = ../../../../../secrets/secrets.yaml;
        mode = "0400";
    };

    systemd.services.media-sync = {
        description = "Pull media from asta into /bigstorage/media-backup";
        after = [ "tailscaled.service" "sops-nix.service" ];
        wants = [ "tailscaled.service" ];

        serviceConfig = {
            Type = "oneshot";
            StateDirectory = "media-sync";

            ConditionPathIsMountPoint = "/bigstorage";

            ExecStart = ''
                ${pkgs.rsync}/bin/rsync \
                    --archive \
                    --partial \
                    --human-readable \
                    --info=stats2 \
                    -e '${pkgs.openssh}/bin/ssh -i ${config.sops.secrets.albireo-media-sync-key.path} -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/var/lib/media-sync/known_hosts' \
                    ${username}@${tailnet.ips.asta}:/home/${username}/media/ \
                    /bigstorage/media-backup/
            '';
        };
    };

    systemd.timers.media-sync = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
            OnCalendar = "daily";
            RandomizedDelaySec = "1h";
            Persistent = true;
        };
    };
}
