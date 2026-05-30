{ config, ... } : {
    services.k3s = {
        extraFlags = toString [
            "--node-ip=100.70.98.107"
            "--flannel-iface=tailscale0"
        ];
    };
}
