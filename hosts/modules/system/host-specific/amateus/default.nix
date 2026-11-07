{ ... } : {
    imports = [
        ./restic-server.nix
        ./restic-retention.nix
        ./monitor-display.nix
    ];

    biggerworld.statAgent.enable = true;

    biggerworld.ups = {
        role = "slave";
        master = "aperture";
    };


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
