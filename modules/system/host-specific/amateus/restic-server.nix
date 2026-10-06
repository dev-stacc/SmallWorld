# Backup target for albireo's irreplaceable datasets.
#
# Append-only on purpose: albireo is the WAN-facing router for its segment, so
# if it is ever compromised this is what stops an attacker deleting the backups
# it just wrote. The consequence is that `restic forget --prune` cannot run from
# albireo - retention has to be driven from here.
#
# amateus never holds the repo encryption password, only restic-server-htpasswd,
# so the data it stores is ciphertext it cannot read.
{ config, tailnet, ... } : {
    sops.secrets.restic-server-htpasswd = {
        sopsFile = ../../../../secrets/secrets.yaml;
        owner = "restic";
        mode = "0400";
    };

    services.restic.server = {
        enable = true;

        # Deliberately NOT under /srv/nfs: that path is managed by the cluster's
        # nfs-provisioner, and a runaway PVC there would take the backups with it.
        dataDir = "/srv/restic";

        appendOnly = true;
        htpasswd-file = config.sops.secrets.restic-server-htpasswd.path;

        # Bound to the tailnet address rather than every interface. A bare port
        # would listen everywhere; the module asserts against a leading ":"
        # because it uses systemd socket activation. FreeBind is set by the
        # module, so this binds fine before tailscale0 is up.
        listenAddress = "${tailnet.ips.amateus}:8000";
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 8000 ];
}
