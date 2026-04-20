{ config, pkgs, inputs, ... } : {
    imports = [
        ./base.nix
        ./hardware-configuration.nix
        ./networking.nix
        ./bluetooth.nix
        ./sound.nix
        ./hyprland.nix
        ./home-manager.nix
        ./stylix.nix
        ./fonts.nix
    ];
}