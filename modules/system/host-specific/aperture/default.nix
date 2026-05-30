{ ... } : {
    imports = [
        ../../common/all/default.nix
        ../../common/servers/k3s-agent.nix
        ./k3s-service.nix
    ];

    networking.hostName = "Aperture";

    boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
    };
}
