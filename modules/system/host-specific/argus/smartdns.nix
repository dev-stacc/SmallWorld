{ config, pkgs, tailnet, ... } :
let
    smartdnsConfig = pkgs.writeText "smartdns.conf" ''
        bind ${tailnet.ips.argus}:53
        bind-tcp ${tailnet.ips.argus}:53

        server 127.0.0.1:5354
        server ${tailnet.ips.sanctuary}:5354

        speed-check-mode ping,tcp:80,tcp:443

        cache-size 0

        log-level info
    '';
in {
    systemd.services.smartdns = {
        description = "smartdns parallel-forwarding DNS in front of Pi-hole + sanctuary";
        after = [ "tailscaled.service" "podman-pihole.service" "network-online.target" ];
        wants = [ "tailscaled.service" "podman-pihole.service" "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
            ExecStart = "${pkgs.smartdns}/bin/smartdns -f -c ${smartdnsConfig}";
            Restart = "always";
            RestartSec = 5;
            AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
            CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
            DynamicUser = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
        };
    };
}
