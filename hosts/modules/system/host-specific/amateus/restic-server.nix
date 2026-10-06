{ config, tailnet, ... } : {
    sops.secrets.restic-server-htpasswd = {
        sopsFile = ../../../../../secrets/secrets.yaml;
        owner = "restic";
        mode = "0400";
    };

    services.restic.server = {
        enable = true;
        dataDir = "/srv/restic";

        # appendOnly means `restic forget --prune` cannot run from albireo;
        # retention has to be driven from here
        appendOnly = true;
        htpasswd-file = config.sops.secrets.restic-server-htpasswd.path;

        # a bare port would listen on every interface; the module asserts
        # against a leading ":" because it uses socket activation
        listenAddress = "${tailnet.ips.amateus}:8000";
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 8000 ];
}
