{ ... } : {
    services = {
        resolved.enable = false;
        tailscale = {
            useRoutingFeatures = "server";
            extraUpFlags = [
                "--advertise-exit-node"
            ];
        };
    };
}
