{ pkgs, ... } : let
    agent = import ./agent.nix { inherit pkgs; };

    oss = import ./oss.nix { inherit pkgs agent; };
in {
    home.packages = [ oss ];
}
