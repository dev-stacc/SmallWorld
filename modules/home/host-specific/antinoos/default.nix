{ pkgs, config, lib, inputs, ... } : {
    imports = [
        ../../common/all/default.nix
        ../../common/desktops/default.nix
        ./sway/default.nix
        ./waybar/default.nix
    ];
}
