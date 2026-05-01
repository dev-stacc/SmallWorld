{ ... } : {
    imports = [
        ./programs/default.nix
        ./nixvim/default.nix
    ];

    programs.home-manager.enable = true;
}
