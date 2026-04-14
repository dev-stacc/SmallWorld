{ config, pkgs, inputs, ... } : {
    imports = [
        ./base.nix
        ./hardware-configuration.nix
        ./networking.nix
        ./bluetooth.nix
        ./sound.nixi
        ./hyprland.nix
        ./home-manager.nix
        ./stylix.nix
    ];
}