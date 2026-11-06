{ ... } : {
    imports = [
        ./k3s-service.nix
        ./monitor.nix
        ./ntfy.nix
    ];

    biggerworld.ups.role = "master";

    biggerworld.serve = {
        node."/" = "http://127.0.0.1:9847";
        services.home."/" = "http://127.0.0.1:9847";
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
