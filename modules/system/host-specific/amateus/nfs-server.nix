{ ... }: {
    services.nfs.server = {
        enable = true;
        exports = ''
            /srv/nfs 100.88.255.118(rw,sync,no_subtree_check,no_root_squash) 100.111.78.27(rw,sync,no_subtree_check,no_root_squash)
        '';
    };

    networking.firewall.allowedTCPPorts = [ 2049 ];
    networking.firewall.allowedUDPPorts = [ 2049 ];

    systemd.tmpfiles.rules = [
        "d /srv/nfs 0755 root root -"
    ];
}
