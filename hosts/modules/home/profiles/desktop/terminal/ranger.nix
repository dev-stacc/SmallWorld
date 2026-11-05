{ pkgs, ... } : {
    home.packages = with pkgs; [
        bat
        glow
        ffmpegthumbnailer
        unar
        jq
        poppler
        fd
        ripgrep
        tdf
    ];

    programs.ranger = {
        enable = true;
        package = pkgs.ranger;
        options = {
            # Basic settings for ranger
            preview_images = true;
            preview_images_method = "kitty";
            save_history = true;
            history_length = 1000;
        };
    };
}