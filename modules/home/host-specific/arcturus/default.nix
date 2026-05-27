{ pkgs, config, lib, inputs, ... } : {
    imports = [
        ../../common/all/default.nix
        ../../common/desktops/default.nix
        ./k3s-control/default.nix
    ];
    
    home.packages = with pkgs; [
        major-mono-display

        nerd-fonts.jetbrains-mono
        hyprpaper
        claude-code
        ungoogled-chromium
        tdf
        libreoffice
    ];
}
