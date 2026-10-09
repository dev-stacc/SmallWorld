{ tailnet, ... } : {
    services.k3s = {
        extraFlags = toString [
            "--node-ip=${tailnet.ips.aperture}"
        ];
    };

    networking.firewall.allowedUDPPorts = [ 51820 ];
}
