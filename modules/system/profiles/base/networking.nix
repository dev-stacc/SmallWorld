{ config, lib, inputs, ... } : {
    imports = [
        inputs.sops-nix.nixosModules.sops
    ];

    options.biggerworld.secrets.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
            Whether this host holds a key able to decrypt secrets/secrets.yaml.

            Set false from hosts/default.nix for hosts deliberately kept without
            secret access - alula, which is easy to steal. Those hosts join the
            tailnet by hand (`tailscale up`) instead of via a sops-provisioned
            auth key, and must also be absent from .sops.yaml.
        '';
    };

    config = {
        networking = {
            firewall = {
                enable = true;
                trustedInterfaces = [ "tailscale0" ];
                allowedUDPPorts = [ config.services.tailscale.port ];
            };
        };

        services = {
            tailscale = {
                enable = true;
                authKeyFile = lib.mkIf config.biggerworld.secrets.enable
                    config.sops.secrets.tailscale-authkey.path;
            };
            openssh = {
                enable = true;

                # Reachable over the tailnet only. tailscale0 is a trusted
                # interface above, so every port is accepted there - opening 22
                # globally would additionally expose it on wifi and ethernet,
                # where a stolen key could be used without touching the tailnet.
                # Trade-off: if tailscaled dies on a rack host, recovery is
                # physical. All SSH and colmena deploys already resolve to
                # tailnet IPs, so this costs nothing day to day.
                openFirewall = false;
                settings = {
                    PasswordAuthentication = false;
                    PubkeyAuthentication = true;
                    PermitRootLogin = "no";
                };
            };
        };

        sops.secrets = lib.mkIf config.biggerworld.secrets.enable {
            tailscale-authkey.sopsFile = ../../../../secrets/secrets.yaml;
        };

        systemd.network.wait-online.enable = false;
        boot.initrd.systemd.network.wait-online.enable = false;
    };
}
