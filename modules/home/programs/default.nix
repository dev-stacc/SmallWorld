{ config, lib, pkga, ... } : {
    imports = [
        ./fzf.nix
        ./git.nix
        ./vesktop.nix
    ];
}
