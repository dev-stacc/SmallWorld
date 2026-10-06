# asta's authorized_keys needs the matching pubkey, restricted to rsync:
#   restrict,command="rsync --server --sender -logDtpre.iLsfxC . /home/anastasia/media/" ssh-ed25519 AAAA...
{ config, pkgs, tailnet, username, ... } : {
    sops.secrets.albireo-media-sync-key = {
        sopsFile = ../../../../secrets/secrets.yaml;
        mode = "0400";
    };

    systemd.services.media-sync = {
        description = "Pull media from asta into /srv/media-backup";
        after = [ "tailscaled.service" "sops-nix.service" "zfs-import.target" ];
        wants = [ "tailscaled.service" ];

        serviceConfig = {
            Type = "oneshot";
            StateDirectory = "media-sync";

            # without this a failed zfs import would let rsync fill the root disk
            ConditionPathIsMountPoint = "/srv/media-backup";

            ExecStart = ''
                ${pkgs.rsync}/bin/rsync \
                    --archive \
                    --delete \
                    --partial \
                    --human-readable \
                    --info=stats2 \
                    -e '${pkgs.openssh}/bin/ssh -i ${config.sops.secrets.albireo-media-sync-key.path} -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/var/lib/media-sync/known_hosts' \
                    ${username}@${tailnet.ips.asta}:/home/${username}/media/ \
                    /srv/media-backup/
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
