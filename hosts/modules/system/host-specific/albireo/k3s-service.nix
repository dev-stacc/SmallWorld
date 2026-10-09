{ lib, tailnet, ... } : {
    services.k3s = {
        enable = lib.mkForce (tailnet.ips.albireo != "PLACEHOLDER");
        extraFlags = toString (
            lib.optional (tailnet.ips.albireo != "PLACEHOLDER")
                "--node-ip=${tailnet.ips.albireo}"
        );
    };

    networking.firewall.allowedUDPPorts = [ 51820 ];
}
