{ username, ... } : {
    imports = [
        ./graphics.nix
        ./hyprland.nix
        ./k3s-kubeconfig.nix
        ./llama-key.nix
        ./lid.nix
        ./overlays.nix
        ./fourget.nix
        ./virtualisation.nix
        ./trackball.nix
    ];

    sops.age.keyFile = "/home/${username}/.sops/keys.txt";


    boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
    };
}
