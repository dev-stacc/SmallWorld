{ pkgs, config, lib, inputs, ... } : {
    imports = [
        ../../common/all/default.nix
    ];

    home.packages = [
        (pkgs.yt-dlp.override { javascriptSupport = false; })
        pkgs.ffmpeg
    ];
}
