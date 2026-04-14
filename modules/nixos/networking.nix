{ config, lib, pkgs, ... } : {
    networking = {
        hostName = "Arcturus"; 
        wireless.iwd = {
            enable = true;
            settings = {
                Network = {
                    EnableIPv6 = true;
                };
                Settings = {
                    AutoConnect = true;
                };
            };
        };
        firewall = {
            enable = true;
            trustedInterfaces = ["tailscale0"];
        };
    };

    services = {
        tailscale.enable = true;
        openssh = {
            enable = true;
            settings.PasswordAuthentication = false;
            settings.PermitRootLogin = "no";
        };
    };

    security.sudo.extraRules = [{
        users = ["anastasia"];
        commands = [{
            command = "${pkgs.tailscale}/bin/tailscale";
            options = ["NOPASSWD"];
        }];
    }];
}