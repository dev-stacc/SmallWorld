{ ... } : {
    imports = [
        ./graphics.nix
        ./storage.nix
        ./sway.nix
    ];


    boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
    };

    swapDevices = [{
        device = "/swapfile";
        size = 16384;
    }];
}
