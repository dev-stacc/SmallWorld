{ username, ... } : {
    imports = [
        ./graphics.nix
        ./hyprland.nix
        ./k3s-kubeconfig.nix
        ./overlays.nix
        ./virtualisation.nix
    ];

    sops.age.keyFile = "/home/${username}/.sops/keys.txt";


    boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
    };
}
