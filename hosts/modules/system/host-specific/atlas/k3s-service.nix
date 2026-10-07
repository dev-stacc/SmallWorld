{ lib, tailnet, ... } : {
    services.k3s = {
        enable = lib.mkForce (tailnet.ips.atlas != "PLACEHOLDER");
        extraFlags = toString (
            lib.optional (tailnet.ips.atlas != "PLACEHOLDER") "--node-ip=${tailnet.ips.atlas}"
        );
    };

    networking.firewall.allowedUDPPorts = [ 51820 ];
}
