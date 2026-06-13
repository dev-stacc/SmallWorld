{ pkgs, config, lib, inputs, ... } : {
    imports = [
        ../../common/all/default.nix
        ../../common/desktops/default.nix
        ./monitor.nix
    ];
}
