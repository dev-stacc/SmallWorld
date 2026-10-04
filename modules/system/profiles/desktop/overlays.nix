{ inputs, ... } : {
    # librewolf pulls tridactyl from pkgs.nur.repos.rycee.firefox-addons,
    # so every host with the desktop profile needs this overlay.
    nixpkgs.overlays = [ inputs.nur.overlays.default ];
}
