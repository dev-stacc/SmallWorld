{ config, pkgs, ... } : {
    environment.systemPackages = with pkgs; [
        fzf
        git
        vim
        sops
        age
    ];
}
