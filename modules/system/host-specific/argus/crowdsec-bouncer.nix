{ config, pkgs, inputs, tailnet, ... } : {
    sops.secrets.crowdsec-bouncer-api-key = {
        sopsFile = ../../../../secrets/secrets.yaml;
    };

    # LAPI_URL was http://${tailnet.ips.asta}:30008 - a NodePort nothing ever
    # served, since k8s/apps/crowdsec/helmrelease.yaml sets
    # lapi.service.type: ClusterIP. `cscli bouncers list` was empty, confirming
    # this bouncer never reached the LAPI. It is exposed on the tailnet instead,
    # by k8s/apps/crowdsec/service.yaml.
    sops.templates."crowdsec-bouncer.env".content = ''
        LAPI_URL=http://${tailnet.ips.crowdsec}:8080
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
