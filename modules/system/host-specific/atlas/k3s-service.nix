{ config, lib, tailnet, ... } : {
    services.k3s = {
        enable = lib.mkForce (tailnet.ips.atlas != "PLACEHOLDER");
        extraFlags = toString (
            [ "--flannel-iface=tailscale0" ]
            ++ lib.optional (tailnet.ips.atlas != "PLACEHOLDER") "--node-ip=${tailnet.ips.atlas}"
        );
    };
}
