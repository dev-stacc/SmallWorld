{ inputs, ... } : {
    imports = [
        inputs.nixvim.homeModules.nixvim
        ./bash.nix
        ./fzf.nix
        ./git.nix
        ./nixvim/default.nix
    ];

    programs.home-manager.enable = true;
}
