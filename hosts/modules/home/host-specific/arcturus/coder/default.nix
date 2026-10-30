{ pkgs, ... } : let
    coder = import ./coder.nix { inherit pkgs; };
in {
    home.packages = [ coder ];
}
