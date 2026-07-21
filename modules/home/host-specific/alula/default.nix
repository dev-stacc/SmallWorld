{ pkgs, config, lib, inputs, ... } : {
    imports = [
        ../../common/all/default.nix
        ../../common/desktops/default.nix
        ./niri/default.nix
        ./waybar/default.nix
    ];
}
