{ ... } : {
    imports = [
        ./graphics.nix
        ./k3s-server.nix
        ../../profiles/server/k3s-node.nix
        ./flux.nix
        ./media.nix
        ./vault.nix
        ./suricata.nix
        ./cluster-dumps.nix
        ./disk-io.nix
        ./flaresolverr-restart.nix
    ];

    biggerworld.ups = {
        role = "slave";
        master = "algol";
    };


    boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
    };
}
