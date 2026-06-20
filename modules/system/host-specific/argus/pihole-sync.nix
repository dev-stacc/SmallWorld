{ config, pkgs, inputs, ... } :
let
    mkService = envFile: {
        after = [ "podman-pihole.service" "tailscaled.service" "sops-nix.service" ];
        wants = [ "podman-pihole.service" ];
        serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.python3}/bin/python3 ${./files/pihole-sync.py}";
            EnvironmentFile = envFile;
            DynamicUser = true;
            NoNewPrivileges = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
        };
    };
in {
    sops.secrets.remote-pihole-url = {
        sopsFile = "${inputs.self}/secrets/secrets.yaml";
    };
    sops.secrets.remote-pihole-api-password = {
        sopsFile = "${inputs.self}/secrets/secrets.yaml";
    };

    sops.templates."pihole-sync-pull.env".content = ''
        PRIMARY_URL=${config.sops.placeholder.remote-pihole-url}
        PRIMARY_PASSWORD=${config.sops.placeholder.remote-pihole-api-password}
        SECONDARY_URL=http://127.0.0.1
        SECONDARY_PASSWORD=${config.sops.placeholder.pihole-web-password}
    '';

    sops.templates."pihole-sync-push.env".content = ''
        PRIMARY_URL=http://127.0.0.1
        PRIMARY_PASSWORD=${config.sops.placeholder.pihole-web-password}
        SECONDARY_URL=${config.sops.placeholder.remote-pihole-url}
        SECONDARY_PASSWORD=${config.sops.placeholder.remote-pihole-api-password}
    '';

    systemd.services.pihole-sync-pull = mkService config.sops.templates."pihole-sync-pull.env".path // {
        description = "Pi-hole sync (pull: remote -> argus)";
    };
    systemd.services.pihole-sync-push = mkService config.sops.templates."pihole-sync-push.env".path // {
        description = "Pi-hole sync (push: argus -> remote)";
    };

    systemd.timers.pihole-sync-pull = {
        description = "Pi-hole sync pull hourly at :00";
        wantedBy = [ "timers.target" ];
        timerConfig = {
            OnCalendar = "*-*-* *:00:00";
            Persistent = true;
        };
    };
    systemd.timers.pihole-sync-push = {
        description = "Pi-hole sync push hourly at :30";
        wantedBy = [ "timers.target" ];
        timerConfig = {
            OnCalendar = "*-*-* *:30:00";
            Persistent = true;
        };
    };
}
