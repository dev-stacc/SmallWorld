{ ... } : {
    imports = [
        ./graphics.nix
        ./k3s-server.nix
        ./flux.nix
        ./media.nix
        ./vault.nix
        ./suricata.nix
        ./media-sync-key.nix
    ];


    boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
    };
}
