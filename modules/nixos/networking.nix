{ config, pkgs, inputs, ... } : {
    imports = [
	      inputs.sops-nix.nixosModules.sops
    ];
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
            trustedInterfaces = [ "tailscale0" ];
            allowedUDPPorts = [ config.services.tailscale.port ];
        };
    };
    services = {
        tailscale = {
            enable = true;
            authKeyFile = config.sops.secrets.tailscale-authkey.path;
        };
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
    sops.secrets.tailscale-authkey = {
        sopsFile = "${inputs.self}/secrets/secrets.yaml";
    };

    systemd.network.wait-online.enable = false; 
    boot.initrd.systemd.network.wait-online.enable = false;
}
