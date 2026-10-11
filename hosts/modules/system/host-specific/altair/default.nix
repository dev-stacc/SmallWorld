{ ... } : {
    imports = [
        ./graphics.nix
        ./storage.nix
        ./models.nix
        ./llama.nix
        ./power.nix
    ];

    biggerworld.serve = {
        node."/" = "http://127.0.0.1:8080";
        services.llama."/" = "http://127.0.0.1:8080";
    };

    boot.loader.grub = {
        enable = true;
        device = "/dev/disk/by-id/ata-TOSHIBA_THNSNF128GCSS_13US1068TH2Y";
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
