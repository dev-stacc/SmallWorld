{ config, tailnet, ... } : {
    services.k3s = {
        extraFlags = toString [
            "--node-ip=${tailnet.ips.atlas}"
            "--flannel-iface=tailscale0"
        ];
    };
}
