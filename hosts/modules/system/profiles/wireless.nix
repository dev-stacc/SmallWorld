{ ... } : {
    # Only the two portable hosts have wifi; everything else is on ethernet.
    networking.wireless.iwd = {
        enable = true;
        settings = {
            Network = {
                EnableIPv6 = true;
                EnableNetworkConfiguration = true;
            };
            Settings = {
                AutoConnect = true;
            };
        };
    };
}
