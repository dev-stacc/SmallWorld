{ ... } : {
    imports = [
        ./nfs-server.nix
        ./restic-server.nix
    ];


    boot.loader.grub = {
        enable = true;
        device = "/dev/sda";
    };

    swapDevices = [{
        device = "/swapfile";
        size = 4096;
    }];

    hardware.graphics = {
        enable = true;
    };
}
