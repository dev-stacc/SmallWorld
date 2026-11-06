{ ... } : {
    imports = [
        ./k3s-service.nix
        ./monitor.nix
        ./ntfy.nix
        ./unbound.nix
        ./pihole.nix
        ./smartdns.nix
    ];

    biggerworld.ups = {
        role = "slave";
        master = "algol";
    };

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

    virtualisation = {
        oci-containers.backend = "podman";
        podman = {
            enable = true;
            autoPrune.enable = true;
            defaultNetwork.settings.dns_enabled = false;
        };
    };
}
