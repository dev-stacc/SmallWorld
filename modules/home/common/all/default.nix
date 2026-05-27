{ inputs, ... } : {
    imports = [
        inputs.nixvim.homeModules.nixvim
        ./fzf.nix
        ./git.nix
        ./nixvim/default.nix
    ];

    programs.home-manager.enable = true;
}
