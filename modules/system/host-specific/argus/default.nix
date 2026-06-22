{ ... } : {
    imports = [
        ../../common/all/default.nix
        ../../common/servers/always-on.nix
        ./networking.nix
        ./unbound.nix
        ./pihole.nix
        ./smartdns.nix
        ./crowdsec-bouncer.nix
        ./pihole-sync.nix
    ];

    networking.hostName = "Argus";

    boot.loader.grub = {
        enable = true;
        device = "/dev/sda";
    };

    # Broken eDP panel; force HDMI as the only display the kernel sees.
    # No-op once the panel is physically stripped.
    boot.kernelParams = [
        "video=eDP-1:d"
        "video=LVDS-1:d"
    ];

    swapDevices = [{
        device = "/swapfile";
        size = 8192;
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
