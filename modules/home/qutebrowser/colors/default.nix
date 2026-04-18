{ config, lib, pkgs, ... } : let
    completion = import ./completion.nix { config lib pkgs; };
    webpage = import ./webpage { config lib pkgs; };
in {
    colors = lib.mkMerge [
        completion
        webpage
    ];
}