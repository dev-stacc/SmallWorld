{ ... } : {
    imports = [
        ./storage.nix
        ./nfs-server.nix
        ./media-sync.nix
        ./backup.nix
        ./k3s-service.nix
        ./graphics.nix
    ];

    boot.loader.grub = {
        enable = true;
        device = "/dev/sda";
    };

    boot.kernelParams = [
        "console=ttyS0,115200n8"
        "console=tty0"
    ];

    zramSwap.enable = true;

    swapDevices = [{
        device = "/swapfile";
        size = 8192;
    }];
}
