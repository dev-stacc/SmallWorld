{ ... } : {
    imports = [
        ../../common/all/default.nix
        ./nfs-server.nix
    ];

    networking.hostName = "Amateus";

    boot.loader.grub = {
        enable = true;
        device = "/dev/sda";
    };

    swapDevices = [{
        device = "/swapfile";
       size = 8192;
    }];

    hardware.graphics = {
        enable = true;
    };
}
