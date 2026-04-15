{ config, lib, pkga, ... } : {
    imports = [
        ./fresh-editor.nix
        ./fzf.nix
        ./git.nix
        ./qutebrowser.nix
        ./vesktop.nix
    ];
}
