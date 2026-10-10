{ ... } : {
    imports = [
        ./nfs-server.nix
        ./restic-server.nix
        ./restic-retention.nix
        ./monitor-display.nix
    ];


    boot.loader.grub = {
        enable = true;
        device = "/dev/disk/by-id/ata-TOSHIBA_MQ01ACF050_695ITBR6T";
    };

    swapDevices = [{
        device = "/swapfile";
        size = 4096;
    }];

    hardware.graphics = {
        enable = true;
    };
}
