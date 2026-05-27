{ inputs, ... } : {
    imports = [
        inputs.nixvim.homeModules.nixvim
        ./programs/default.nix
        ./nixvim/default.nix
    ];

    programs.home-manager.enable = true;
}
