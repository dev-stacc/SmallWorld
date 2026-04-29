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
