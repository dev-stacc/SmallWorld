{ lib, tailnet, ... } : {
    services.k3s = {
        enable = lib.mkForce (tailnet.ips.albireo != "PLACEHOLDER");
        extraFlags = toString (
            [ "--flannel-iface=tailscale0" ]
            ++ lib.optional (tailnet.ips.albireo != "PLACEHOLDER")
                "--node-ip=${tailnet.ips.albireo}"
        );
    };
}
