{ lib, tailnet, ... } : {
    services.k3s = {
        enable = lib.mkForce (tailnet.ips.albireo != "PLACEHOLDER");
        extraFlags = toString (
            [ "--flannel-iface=enp2s0" ]
            ++ lib.optional (tailnet.ips.albireo != "PLACEHOLDER")
                "--node-ip=${tailnet.ips.albireo}"
        );
    };

    networking.firewall.interfaces.enp2s0.allowedUDPPorts = [ 8472 51820 ];
}
