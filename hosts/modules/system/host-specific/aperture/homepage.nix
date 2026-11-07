{ config, lib, pkgs, tailnet, theme, ... } :
let
    port = 9850;
    collectorPort = 9847;

    secretsFile = ../../../../../secrets/secrets.yaml;

    fleet = import ./fleet.nix { inherit lib tailnet; };

    selfPages = "https://home.${tailnet.domain}";

    links = builtins.filter
        (app: !(lib.hasPrefix selfPages app.url))
        fleet.apps;

    settings = {
        inherit links;
        inherit (fleet) expectedBackups backupStaleHours agents;
    };

    configFile = pkgs.writeText "homepage-config.json" (builtins.toJSON settings);

    palette = lib.mapAttrs' (name: value:
        lib.nameValuePair "THEME_${lib.toUpper name}" value
    ) (lib.filterAttrs
        (name: _: builtins.elem name [
            "base00" "base01" "base02" "base03" "base04"
            "base05" "base06" "base07" "base08"
        ])
        theme.base16);
in {
    sops = {
        secrets.stat-agent-token.sopsFile = secretsFile;

        templates."homepage.env" = {
            restartUnits = [ "podman-homepage.service" ];
            content = ''
                AGENT_TOKEN=${config.sops.placeholder.stat-agent-token}
            '';
        };
    };

    virtualisation.oci-containers.containers.homepage = {
        image = "ghcr.io/dev-stacc/biggerworldhomepage:latest";
        autoStart = true;

        environment = palette // {
            NODE_ENV = "production";
            PORT = toString port;
            HOSTNAME = "127.0.0.1";
            CONFIG_PATH = "/etc/homepage/config.json";
            COLLECTOR_URL = "http://127.0.0.1:${toString collectorPort}";
            THEME_FONT_SIZE = toString theme.fonts.sizes.applications;
            THEME_NUMERIC_SIZE = "15";
            THEME_TAB_SLOPE = toString theme.tabs.slope;
            TZ = "America/Toronto";
        };

        environmentFiles = [
            config.sops.templates."homepage.env".path
        ];

        volumes = [
            "${configFile}:/etc/homepage/config.json:ro"
        ];

        extraOptions = [ "--network=host" ];
    };

    systemd.services."podman-homepage" = {
        after = [ "sops-nix.service" "tailscaled.service" "monitor-poll.service" ];
    };
}
