{ config, pkgs, ... } : {
    environment.systemPackages = with pkgs; [
        fzf
        git
        waybar
        kitty
        vim
    ];
}
