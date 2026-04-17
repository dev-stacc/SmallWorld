{ config, lib, pkga, ... } : {
    imports = [
        ./fresh-editor.nix
        ./fzf.nix
        ./git.nix
        ./vesktop.nix
    ];
}
