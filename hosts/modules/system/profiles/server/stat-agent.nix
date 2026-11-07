{ config, lib, pkgs, tailnet, ... } :
let
    cfg = config.biggerworld.statAgent;

    secretsFile = ../../../../../secrets/secrets.yaml;

    hostName = lib.toLower config.networking.hostName;
    bind = tailnet.ips.${hostName} or "PLACEHOLDER";

    runtimeDir = "stat-agent";
    smartPath = "/run/${runtimeDir}/smart.json";
in {
    options.biggerworld.statAgent = {
        enable = lib.mkEnableOption ''
            the read-only host stat agent consumed by the homepage.

            Serves a single JSON block over HTTP on this host's tailnet address
            only, so it is unreachable from the LAN, and requires a bearer token
            from sops. It holds a rolling in-memory window of samples so the
            homepage can draw history without Prometheus, which matters because
            Prometheus lives in the cluster the homepage is meant to report on.
        '';

        port = lib.mkOption {
            type = lib.types.port;
            default = 9848;
            description = ''
                Port to serve on, bound to the tailnet address rather than
                0.0.0.0. Must match the `agents` entry in the homepage config.
            '';
        };

        interval = lib.mkOption {
            type = lib.types.ints.positive;
            default = 15;
            description = "Seconds between samples pushed into the history ring.";
        };

        depth = lib.mkOption {
            type = lib.types.ints.positive;
            default = 240;
            description = ''
                Samples retained per series. At the default interval this is one
                hour of history, held in memory and lost on restart by design -
                there is no on-disk state to back up or corrupt.
            '';
        };

        smartInterval = lib.mkOption {
            type = lib.types.str;
            default = "10min";
            description = ''
                How often the privileged SMART collector runs. Separate from the
                sample interval because it spins disks and needs CAP_SYS_RAWIO,
                so it is deliberately infrequent and deliberately not the
                process listening on a port.
            '';
        };
    };

    config = lib.mkIf cfg.enable {
        assertions = [
            {
                assertion = bind != "PLACEHOLDER";
                message =
                    "biggerworld.statAgent is enabled on ${hostName} but its"
                    + " tailnet address in flake.nix is still PLACEHOLDER, so the"
                    + " agent has no address to bind to.";
            }
            {
                assertion = config.biggerworld.secrets.enable;
                message =
                    "biggerworld.statAgent is enabled on ${hostName} but that host"
                    + " has secrets disabled, so it cannot read the bearer token.";
            }
        ];

        sops.secrets.stat-agent-token.sopsFile = secretsFile;

        systemd.tmpfiles.rules = [
            "d /run/${runtimeDir} 0755 root root -"
        ];

        systemd.services.stat-agent-smart = {
            description = "Collect SMART data for the stat agent";
            after = [ "local-fs.target" ];
            path = [ pkgs.smartmontools ];

            environment.SMART_OUT = smartPath;

            serviceConfig = {
                Type = "oneshot";
                ExecStart = "${pkgs.python3}/bin/python3 ${./files/stat-smart.py}";
                ReadWritePaths = [ "/run/${runtimeDir}" ];
                CapabilityBoundingSet = [ "CAP_SYS_RAWIO" "CAP_SYS_ADMIN" ];
                PrivateNetwork = true;
                ProtectSystem = "strict";
                ProtectHome = true;
                ProtectKernelModules = true;
                ProtectControlGroups = true;
                PrivateTmp = true;
                NoNewPrivileges = true;
                RestrictAddressFamilies = [ "AF_UNIX" ];
                RestrictNamespaces = true;
                LockPersonality = true;
                MemoryDenyWriteExecute = true;
                SystemCallFilter = [ "@system-service" ];
                SystemCallArchitectures = "native";
            };
        };

        systemd.timers.stat-agent-smart = {
            description = "Periodic SMART collection for the stat agent";
            wantedBy = [ "timers.target" ];

            timerConfig = {
                OnBootSec = "2min";
                OnUnitActiveSec = cfg.smartInterval;
                AccuracySec = "30s";
                Persistent = false;
            };
        };

        systemd.services.stat-agent = {
            description = "Read-only host stat agent";
            after = [ "network-online.target" "sops-nix.service" "tailscaled.service" ];
            wants = [ "network-online.target" ];
            wantedBy = [ "multi-user.target" ];

            environment = {
                AGENT_PORT = toString cfg.port;
                AGENT_BIND = bind;
                AGENT_SMART_PATH = smartPath;
                AGENT_INTERVAL = toString cfg.interval;
                AGENT_DEPTH = toString cfg.depth;
            };

            serviceConfig = {
                ExecStart = "${pkgs.python3}/bin/python3 ${./files/stat-agent.py}";
                LoadCredential = [
                    "token:${config.sops.secrets.stat-agent-token.path}"
                ];
                Restart = "always";
                RestartSec = 10;
                DynamicUser = true;
                CapabilityBoundingSet = [ "" ];
                AmbientCapabilities = [ "" ];
                NoNewPrivileges = true;
                ProtectSystem = "strict";
                ProtectHome = true;
                ProtectKernelTunables = true;
                ProtectKernelModules = true;
                ProtectControlGroups = true;
                PrivateTmp = true;
                PrivateDevices = true;
                RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
                RestrictNamespaces = true;
                LockPersonality = true;
                MemoryDenyWriteExecute = true;
                SystemCallFilter = [ "@system-service" ];
                SystemCallArchitectures = "native";
                IPAddressAllow = [ "localhost" "100.64.0.0/10" ];
                IPAddressDeny = "any";
            };
        };
    };
}
