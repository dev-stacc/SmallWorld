{ config, ... } : {
    sops = {
        age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        secrets.k3s-token = {
            sopsFile = ../../../../../secrets/secrets.yaml;
        };
    };

    services.k3s = {
        enable = true;
        role = "agent";
        tokenFile = config.sops.secrets.k3s-token.path;
        serverAddr = "https://asta:6443";
        extraFlags = toString [
            "--node-ip=100.70.98.107"
            "--flannel-iface=tailscale0"
        ];
    };

    boot = {
        kernel.sysctl."net.ipv4.ip_forward" = 1;
        kernelModules = [ "br-netfiller" "overlay" ];
    };
}
