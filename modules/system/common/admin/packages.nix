{ config, pkgs, ... } : {
    environment.systemPackages = with pkgs; [
        colmena
        kubectl
        kubernetes-helm
        fluxcd
        vault
    ];
}
