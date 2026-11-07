{ ... } : {
    imports = [
        ./lean.nix
        ./provision.nix
        ./standalone.nix
        ./unbound.nix
        ./pihole.nix
    ];

    services.tailscale.extraUpFlags = [ "--advertise-tags=tag:offsite" ];

    virtualisation = {
        oci-containers.backend = "podman";
        podman = {
            enable = true;
            autoPrune.enable = true;
            defaultNetwork.settings.dns_enabled = false;
        };
    };
}
