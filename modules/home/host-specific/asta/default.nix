{ pkgs, config, lib, inputs, ... } : {
    imports = [
        ../../common/all/default.nix
    ];

    home.packages = [
        (pkgs.yt-dlp.override { jsRuntime = pkgs.nodejs; })
        pkgs.ffmpeg
    ];
}
