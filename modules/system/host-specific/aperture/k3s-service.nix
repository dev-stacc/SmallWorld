{ config, tailnet, ... } : {
    services.k3s = {
        extraFlags = toString [
            "--node-ip=${tailnet.ips.aperture}"
            "--flannel-iface=tailscale0"
        ];
    };
}
