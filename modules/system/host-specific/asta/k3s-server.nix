{ config, pkgs, ... } : {
    sops = {
        age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        secrets.k3s-token = {
            sopsFile = ../../../../secrets/secrets.yaml;
        };
    };

    services.k3s = {
        enable = true;
        role = "server";
        tokenFile = config.sops.secrets.k3s-token.path;
        extraFlags = toString [
            "--disable traefik"
            "--node-ip=100.88.255.118"
            "--advertise-address=100.88.255.118"
            "--tls-san=asta"
            "--tls-san=<asta-tailscale-ip>"
            "--flannel-iface=tailscale0"
        ];
    };

    services.nfs.client.enable = true;

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

    systemd.services.k3s-kubeconfig-permissions = {
        description = "Fix k3s kubeconfig permissions";
        after = [ "k3s.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${pkgs.coreutils}/bin/chmod 644 /etc/rancher/k3s/k3s.yaml";
        };
    };
}
