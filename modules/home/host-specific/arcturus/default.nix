{ pkgs, config, lib, inputs, ... } : {
    imports = [
        ../../common/all/default.nix
        ../../common/desktops/default.nix
        ./k3s-control/default.nix
        ./niri/default.nix
        ./ssh.nix
        ./swaybg.nix
        ./waybar/default.nix
    ];
    
    home.packages = with pkgs; [
        claude-code
        libreoffice
    ];
}
