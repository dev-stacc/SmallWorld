{ pkgs, ... } : let
    sort-music = import ./sort-music.nix { inherit pkgs; };
in {
    imports = [
        ./yt-dlp.nix
    ];

    home.packages = [ sort-music ];
}
