{ pkgs, config, lib, inputs, ... } : {
    imports = [
        ../../common/all/default.nix
        ./yt-dlp.nix
    ];
}
