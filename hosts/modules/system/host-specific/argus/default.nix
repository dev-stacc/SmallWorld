{ config, ... } : {
    imports = [
        ./lean.nix
        ./provision.nix
        ./standalone.nix
        ./unbound.nix
        ./pihole.nix
        ../../profiles/pihole-rules
    ];

    biggerworld.piholeRules.envFile = "${config.biggerworld.provision.dir}/pihole.env";

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
