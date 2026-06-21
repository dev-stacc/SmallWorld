{ inputs, username, ... } : {
    imports = [
        inputs.sops-nix.nixosModules.sops
        ../../common/all/default.nix
        ../../common/admin/default.nix
        ../../common/desktops/default.nix
        ./graphics.nix
        ./hyprland.nix
        ./k3s-kubeconfig.nix
        ./overlays.nix
        ./virtualisation.nix
    ];

    sops.age.keyFile = "/home/${username}/.sops/keys.txt";

    networking.hostName = "Arcturus";

    boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
    };
}
