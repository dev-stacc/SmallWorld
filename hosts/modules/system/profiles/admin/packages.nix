{ pkgs, ... } : {
    environment.systemPackages = with pkgs; [
        gh
        colmena
        kubectl
        kubernetes-helm
        fluxcd
        vault
    ];
}
