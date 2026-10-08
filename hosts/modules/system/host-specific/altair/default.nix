{ ... } : {
    imports = [
        ./graphics.nix
        ./storage.nix
        ./models.nix
        ./llama.nix
        ./power.nix
    ];

    boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
    };

    boot.kernelParams = [
        "console=ttyS0,115200n8"
        "console=tty0"
    ];

    zramSwap.enable = true;

    swapDevices = [{
        device = "/swapfile";
        size = 16384;
    }];
}
