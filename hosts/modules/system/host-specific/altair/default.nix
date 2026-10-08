{ ... } : {
    imports = [
        ./graphics.nix
        ./storage.nix
        ./models.nix
        ./llama.nix
        ./power.nix
    ];

    boot.loader.grub = {
        enable = true;
        device = "/dev/disk/by-id/PLACEHOLDER";
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
