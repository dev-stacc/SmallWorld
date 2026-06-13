{ pkgs, config, lib, inputs, ... } : {
    imports = [
        ../../common/all/default.nix
        ../../common/desktops/default.nix
        ./hyprland/default.nix
        ./hyprpaper.nix
        ./k3s-control/default.nix
        ./ssh.nix
    ];
    
    home.packages = with pkgs; [
        claude-code
        ungoogled-chromium
        libreoffice
    ];
}
