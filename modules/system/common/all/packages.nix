{ config, pkgs, ... } : {
    environment.systemPackages = with pkgs; [
        fzf
        git
        vim
        colmena
        kubectl
        sops
        age
        kubernetes-helm
        fluxcd
        vault
    ];
}
