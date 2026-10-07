{ ... } : {
    imports = [
        ./storage.nix
        ./nfs-server.nix
        ./media-sync.nix
        ./backup.nix
        ./k3s-service.nix
        ./graphics.nix
        ./crowdsec-bouncer.nix
    ];

    boot.loader.grub = {
        enable = true;
        device = "/dev/disk/by-id/ata-SanDisk_SDSSDRC032G_143235415768";
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
