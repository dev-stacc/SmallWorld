{ ... }: {
    imports = [
        ./bind.nix
        ./general.nix
        ./input.nix
        ./output.nix
    ];

    programs.niri.enable = true;
}
