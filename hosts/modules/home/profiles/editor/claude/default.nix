{ pkgs, ... } : let
    trimmed = import ./claude.nix { inherit pkgs; };

    full = import ./full.nix { inherit pkgs; };
in {
    home.packages = [ trimmed full ];

    home.file.".claude/agents/cheap.md".source = ./cheap.md;
}
