{ lib, tailnet, ... } : {
    services.k3s = {
        enable = lib.mkForce (tailnet.ips.avior != "PLACEHOLDER");
        extraFlags = toString (
            lib.optional (tailnet.ips.avior != "PLACEHOLDER") "--node-ip=${tailnet.ips.avior}"
        );
    };

    networking.firewall.allowedUDPPorts = [ 51820 ];
}
