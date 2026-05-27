{ config, pkgs, inputs, ... } : {
    imports = [
        inputs.sops-nix.nixosModules.sops
        ../../common/all/default.nix
        ../../common/desktops/default.nix
        ./graphics.nix
        ./moonlight
        ./overlays.nix
    ];

    sops.age.keyFile = "/home/anastasia/.sops/keys.txt";

    networking.hostName = "Arcturus";

    boot = {
        loader.systemd-boot.enable = true;
        loader.efi.canTouchEfiVariables = true;
    };
}
