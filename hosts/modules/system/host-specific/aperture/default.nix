{ ... } : {
    imports = [
        ./k3s-service.nix
    ];

    biggerworld.ups = {
        role = "slave";
        master = "algol";
    };


    boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
    };

    swapDevices = [{
        device = "/swapfile";
        size = 12288;
    }];
}
