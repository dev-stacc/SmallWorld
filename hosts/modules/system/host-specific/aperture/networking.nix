{ ... } : {
    services.tailscale = {
        useRoutingFeatures = "server";
        extraSetFlags = [
            "--advertise-exit-node"
        ];
    };
}
