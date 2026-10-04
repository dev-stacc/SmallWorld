{ ... } : {
    imports = [
        ./k3s-service.nix
    ];


    boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
    };

    swapDevices = [{
        device = "/swapfile";
        size = 12288;
    }];
}
