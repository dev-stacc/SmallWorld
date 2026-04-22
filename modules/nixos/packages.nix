{ config, pkgs, ... } : {
    environment.systemPackages = with pkgs; [
        vesktop
        fzf
        git
        waybar
        kitty
        vim
    ];
}