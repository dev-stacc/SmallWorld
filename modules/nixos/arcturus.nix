{ config, pkgs, inputs, ... } : {
    imports = [
        inputs.sops-nix.nixosModules.sops
        ./common.nix
        ./bluetooth.nix
        ./sound.nix
        ./hyprland.nix
        ./overlays.nix
        ./steam.nix
        ./unfreePredicates.nix
    ];

    sops.age.keyFile = "/home/anastasia/.sops/keys.txt";

    networking.hostName = "Arcturus";

    boot = {
        loader.systemd-boot.enable = true;
        loader.efi.canTouchEfiVariables = true;
    };

    hardware.graphics = {
        enable = true;
        extraPackages = with pkgs; [
            intel-media-driver
        ];
    };
}
