{ config, pkgs, ... } : {
    sops = {
        age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        secrets.k3s-token = {
            sopsFile = ../../secrets/secrets.yaml;
        };
    };

    services.k3s = {
        enable = true;
        role = "server";
        tokenFile = config.sops.secrets.k3s-token.path;
        extraFlags = "--disable traefik";
    };

    boot = {
        kernel.sysctl."net.ipv4.ip_forward" = 1;
        kernelModules = [ "br_netfilter"  "overlay" ];
    };

    networking.firewall = {
        allowedTCPPorts = [ 6443 10250 ];
        allowedUDPPorts = [ 8472 ];
    };

    environment = {
        variables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
        systemPackages = [
            pkgs.kubectl
        ];
    };
}
