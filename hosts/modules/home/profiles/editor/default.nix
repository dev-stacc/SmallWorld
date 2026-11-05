{ inputs, ... } : {
    imports = [
        inputs.nixvim.homeModules.nixvim
        ./nixvim/default.nix
        ./claude/default.nix
    ];

    programs.nixvim.nixpkgs.useGlobalPackages = true;
}
