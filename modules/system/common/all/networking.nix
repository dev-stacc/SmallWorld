{ config, inputs, ... } : {
    imports = [
	      inputs.sops-nix.nixosModules.sops
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
    };
    sops.secrets.tailscale-authkey = {
        sopsFile = "${inputs.self}/secrets/secrets.yaml";
    };

    systemd.network.wait-online.enable = false;
    boot.initrd.systemd.network.wait-online.enable = false;

}
