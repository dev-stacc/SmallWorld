{ config, lib, pkgs, ... } : {
    environment.systemPackages = [
        pkgs.ethtool
    ];    

    networking = {
        wireless = {
            iwd = {
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
        };

        firewall = {
            enable = true;
            trustedInterfaces = ["tailscale0"];
            allowedUDPPorts = [config.services.tailscale.port];
        };
    };

    services = {
        tailscale.enable = true;
        openssh = {
            enable = true;
            settings = {
                PasswordAuthentication = false;
                PubkeyAuthentication = true;
                PermitRootLogin = "no";
            };
        };
        networkd-dispatcher = {
            enable = true;
            rules."50-tailscale-optimizations" = {
                onState = [ "routable" ];
                script = ''
                    ${pkgs.ethtool}/bin/ethtool -K eth0 rx-udp-gro-forwarding on rx-gro-list off
                '';
              };
          };
    };

    sops.secrets.tailscale-authKey = {
        sopsFile = ../../secrets/secrets.yaml;
    };

    systemd.services.tailscale-autoconnect = {
        after = [ "tailscaled.service" ];
        wants = [ "tailscaled.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig.Type = "oneshot";
        script = ''
            if ${pkgs.tailscale}/bin/tailscale status --json | ${pkgs.jq}/bin/jq -e '.BackendState == "Running"' > /dev/null; then
                exit 0
            fi
            ${pkgs.tailscale}/bin/tailscale up \
                --authkey=$(cat ${config.sops.secrets.tailscale-authkey.path}) \
                --accept-routes
        '';
    };

    security.sudo.extraRules = [{
        users = ["anastasia"];
        commands = [{
            command = "${pkgs.tailscale}/bin/tailscale";
            options = ["NOPASSWD"];
        }];
    }];

    systemd.network.wait-online.enable = false; 
    boot.initrd.systemd.network.wait-online.enable = false;
}
