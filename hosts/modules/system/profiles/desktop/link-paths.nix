{ ... } : {
    # .desktop entries and portal definitions only matter with a graphical
    # session; direnv is for working on code, which happens on these hosts.
    environment.pathsToLink = [
        "/share/applications"
        "/share/xdg-desktop-portal"
    ];

    programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
    };
}
