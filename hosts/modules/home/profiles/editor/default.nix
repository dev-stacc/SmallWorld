{ inputs, ... } : {
    imports = [
        inputs.nixvim.homeModules.nixvim
        ./nixvim/default.nix
    ];

    # nixvim warns that `inputs.nixvim.inputs.nixpkgs.follows = "nixpkgs"` moved
    # its `nixpkgs.source` default off nixvim's own pin. That warning is
    # advisory and deliberately left alone: nixvim's home-manager module already
    # reuses our `pkgs`, and setting `nixpkgs.source` explicitly to silence it
    # would push the option off default priority, which makes nixvim import a
    # second nixpkgs `lib` instance (see modules/top-level/nixpkgs.nix).
}
