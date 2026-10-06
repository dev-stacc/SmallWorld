{ ... } : {
    imports = [
        ./bash.nix
        ./fzf.nix
        ./git.nix
    ];

    programs.home-manager.enable = true;
}
