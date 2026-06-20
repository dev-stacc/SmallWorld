{ config, pkgs, inputs, tailnet, ... } : {
    sops.secrets.crowdsec-bouncer-api-key = {
        sopsFile = "${inputs.self}/secrets/secrets.yaml";
    };

    sops.templates."crowdsec-bouncer.env".content = ''
        LAPI_URL=http://${tailnet.ips.asta}:30008
        BOUNCER_API_KEY=${config.sops.placeholder.crowdsec-bouncer-api-key}
        PIHOLE_URL=http://127.0.0.1
        PIHOLE_PASSWORD=${config.sops.placeholder.pihole-web-password}
    '';

    systemd.services.crowdsec-pihole-bouncer = {
        description = "CrowdSec -> Pi-hole bouncer";
        after = [ "podman-pihole.service" "tailscaled.service" "sops-nix.service" ];
        wants = [ "podman-pihole.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
            ExecStart = "${pkgs.python3}/bin/python3 ${./files/crowdsec-pihole-bouncer.py}";
            EnvironmentFile = config.sops.templates."crowdsec-bouncer.env".path;
            Restart = "always";
            RestartSec = 10;
            DynamicUser = true;
            NoNewPrivileges = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
        };
    };
}
