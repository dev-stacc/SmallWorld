{ inputs, ... } : {
    imports = [
        inputs.nixvim.homeModules.nixvim
        ./nixvim/default.nix
    ];

    programs.nixvim.nixpkgs.useGlobalPackages = true;
}
