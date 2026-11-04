{ pkgs, theme, ... } : let
    settings = import ./settings.nix { inherit pkgs theme; };

    qwen = import ./qwen.nix { inherit pkgs theme settings; };
in {
    home.packages = [ qwen ];
}
