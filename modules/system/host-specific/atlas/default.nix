{ ... } : {
    imports = [
        ../../common/all/default.nix
        ../../common/servers/always-on.nix
        ../../common/servers/k3s-agent.nix
        ./k3s-service.nix
        ./media.nix
        ./nfs-server.nix
    ];

    networking.hostName = "Atlas";

    boot.loader.grub = {
        enable = true;
        device = "/dev/sda";
    };
}
