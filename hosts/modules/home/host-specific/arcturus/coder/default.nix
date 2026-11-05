{ pkgs, theme, ... } : let
    coder = import ./coder.nix { inherit pkgs theme; };
in {
    home.packages = [ coder ];
}
