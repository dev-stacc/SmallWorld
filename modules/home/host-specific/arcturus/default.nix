{ pkgs, config, lib, inputs, ... } : {
    imports = [
        inputs.nixcord.homeModules.nixcord
        ./common.nix
        ./cursors/default.nix
        ./hyprland/default.nix
        ./terminal/default.nix
        ./waybar/default.nix
        ./qutebrowser/default.nix
        ./nixcord/default.nix
        ./fonts.nix
        ./services/hyprpaper.nix
        ./services/mako.nix
        ./k3s/default.nix
    ];
    
    home.packages = with pkgs; [
        major-mono-display

        nerd-fonts.jetbrains-mono
        hyprpaper
        claude-code
        ungoogled-chromium
        tdf
        libreoffice
    ];
}
