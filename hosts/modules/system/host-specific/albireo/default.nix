{ ... } : {
    imports = [
        ./storage.nix
        ./backup.nix
        ./forge-mirror.nix
        ./restic-cluster-server.nix
        ./k3s-service.nix
        ./crowdsec-bouncer.nix
    ];

    biggerworld.statAgent.enable = true;

    biggerworld.ups = {
        role = "slave";
        master = "aperture";
    };

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
