{ ... } : {
    imports = [
        ../../common/all/default.nix
        ./networking.nix
        ./unbound.nix
        ./pihole.nix
        ./crowdsec-bouncer.nix
        ./pihole-sync.nix
    ];

    networking.hostName = "Argus";

    boot.loader.grub = {
        enable = true;
        device = "/dev/sda";
    };

    swapDevices = [{
        device = "/swapfile";
        size = 4096;
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
