{ config, pkgs, ... } : {
    environment.systemPackages = with pkgs; [
        fresh-editor
        vesktop
        fzf
        git
        waybar
        kitty
        vim
    ];
}