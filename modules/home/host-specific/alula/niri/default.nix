{ inputs, ... }: {
    imports = [
        inputs.niri.homeModules.niri
        ./bind.nix
        ./general.nix
        ./input.nix
        ./output.nix
    ];

    programs.niri.enable = true;
}
