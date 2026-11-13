{ config, ... } : {
    imports = [
        ./k3s-service.nix
        ./networking.nix
        ./monitor.nix
        ./homepage.nix
        ./ntfy.nix
        ./unbound.nix
        ./pihole.nix
        ./smartdns.nix
        ./crowdsec-bouncer.nix
        ./pihole-sync.nix
        ../../profiles/pihole-rules
    ];

    biggerworld.piholeRules = {
        envFile = config.sops.templates."pihole.env".path;
        onCalendar = "*-*-* *:55:00";
    };

    biggerworld.statAgent.enable = true;

    biggerworld.ups.role = "master";

    biggerworld.serve = {
        node."/" = "http://127.0.0.1:9847";
        services.home."/" = "http://127.0.0.1:9850";
        services.pihole."/" = "http://127.0.0.1:8081";
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
