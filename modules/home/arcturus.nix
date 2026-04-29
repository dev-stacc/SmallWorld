{ pkgs, config, lib, inputs, ... } : {
    imports = [
        inputs.nixvim.homeModules.nixvim
        inputs.nixcord.homeModules.nixcord
        ./common.nix
        ./hyprland/default.nix
        ./terminal/default.nix
        ./waybar/default.nix
        ./qutebrowser/default.nix
        ./nixcord/default.nix
        ./nixvim/default.nix
        ./fonts.nix
        ./services/hyprpaper.nix
        ./services/mako.nix
    ];
    
    home.packages = with pkgs; [
        departure-mono
        nerd-fonts.jetbrains-mono
        hyprpaper
        claude-code
        ungoogled-chromium
        tdf
    ];
}
