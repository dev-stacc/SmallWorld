{ pkgs, config, lib, inputs, ... } : {
    imports = [
        ../../common/all/default.nix
        ../../common/desktops/default.nix
        ./niri/default.nix
        ./waybar/default.nix
    ];

    home.packages = with pkgs; [
        brave
        gh
        claude-code
    ];
}
