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
    
    fonts.packages = with pkgs; [
        departure-mono
    ];
    
    fonts.fontConfig.enable = true;
}