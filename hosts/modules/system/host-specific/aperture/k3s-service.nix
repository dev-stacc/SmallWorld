{ tailnet, ... } : {
    services.k3s = {
        extraFlags = toString [
            "--node-ip=${tailnet.ips.aperture}"
            "--flannel-iface=enp3s0"
        ];
    };

    networking.firewall.interfaces.enp3s0.allowedUDPPorts = [ 51820 ];
}
