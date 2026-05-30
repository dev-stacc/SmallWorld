{ config, ... } : {
    services.k3s = {
        extraFlags = toString [
            "--node-ip=100.111.78.27"
            "--flannel-iface=tailscale0"
        ];
    };
}
