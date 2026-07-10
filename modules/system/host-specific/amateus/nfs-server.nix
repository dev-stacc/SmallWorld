{ tailnet, ... }: {
    services.nfs.server = {
        enable = true;
        exports = ''
            /srv/nfs ${tailnet.ips.aperture}(rw,sync,no_subtree_check,root_squash)
        '';
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 111 2049 ];
    networking.firewall.interfaces.tailscale0.allowedUDPPorts = [ 111 2049 ];

    systemd.tmpfiles.rules = [
        "d /srv/nfs 0755 root root -"
    ];
}
