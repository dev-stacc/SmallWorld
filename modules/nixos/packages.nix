{ config, pkgs, ... } : {
    environment.systemPackages = with pkgs; [
        departure-mono
        fresh-editor
        vesktop
        fzf
        git
        waybar
        kitty
        vim
    ];
}