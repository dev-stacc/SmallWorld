{ config, pkgs, ... } : {
    environment.pathsToLink = [
        "/share/applications"
        "/share/xdg-desktop-portal"
    ];

    programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
    };
}
