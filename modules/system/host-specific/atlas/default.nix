{ ... } : {
    imports = [
        ./k3s-service.nix
        ./media.nix
        ./nfs-server.nix
    ];


    boot.loader.grub = {
        enable = true;
        device = "/dev/sda";
    };
}
