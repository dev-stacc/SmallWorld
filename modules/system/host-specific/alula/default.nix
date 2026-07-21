{ inputs, ... }: {
    imports = [
        ../../common/all/default.nix
        ../../common/desktops/default.nix
        ./niri.nix
    ];
}
