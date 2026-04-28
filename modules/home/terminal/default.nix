{ config, lib, pkgs, ... } : {
    imports = [
        ./kitty.nix
        ./home-files.nix
        ./yazi.nix
    ];
}
