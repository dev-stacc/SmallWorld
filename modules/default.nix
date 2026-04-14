{ config, pkgs, inputs, ... } : {
    imports = [
        ./nixos/default.nix
        ./home/default.nix
    ];
}