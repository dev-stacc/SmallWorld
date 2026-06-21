{ ... } : {
    services = {
        resolved.enable = false;
        tailscale = {
            useRoutingFeatures = "server";
            extraUpFlags = [
                "--advertize-exit-node"
            ];
        };
    };
}
