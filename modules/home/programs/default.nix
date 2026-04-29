{ config, lib, pkgs, ... } : {
    imports = [
        ./fzf.nix
        ./git.nix
    ];
}
