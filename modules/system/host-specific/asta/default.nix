{ ... } : {
    imports = [
        ../../common/all/default.nix
        ../../common/servers/always-on.nix
        ./graphics.nix
        ./k3s-server.nix
        ./flux.nix
        ./media.nix
        ./vault.nix
        ./suricata.nix
    ];

    networking.hostName = "Asta";

    boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
    };
}
