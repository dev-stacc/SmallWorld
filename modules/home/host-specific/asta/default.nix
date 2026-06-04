{ pkgs, config, lib, inputs, ... } : {
    imports = [
        ../../common/all/default.nix
    ];

    home.packages = with pkgs; [
        yt-dlp
    ];
}
