{ ... } :
let
    ntp = [
        "162.159.200.1"
        "162.159.200.123"
        "216.239.35.0"
        "216.239.35.4"
    ];
in {
    services.tailscale.extraSetFlags = [ "--accept-dns=false" ];

    networking.resolvconf.useLocalResolver = true;

    services.timesyncd.servers = ntp;
    networking.timeServers = ntp;
}
