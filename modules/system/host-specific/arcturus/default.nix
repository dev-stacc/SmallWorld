{ config, pkgs, inputs, ... } : {
    imports = [
        inputs.sops-nix.nixosModules.sops
        ../../common/all/default.nix
        ../../common/desktops/bluetooth.nix
        ../../common/desktops/sound.nix
        ../../common/desktops/hyprland.nix
        ./overlays.nix
        ../../common/desktops/steam.nix
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
