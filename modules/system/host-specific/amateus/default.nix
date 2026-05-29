{ ... } : {
    imports = [
        ../../common/all/default.nix
        ../../common/servers/k3s-agent.nix
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
