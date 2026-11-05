{ pkgs, ... } : let
    tools = with pkgs; [
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
in {
    home.packages = tools;

    programs.ranger = {
        enable = true;
        package = pkgs.ranger;

        extraPackages = tools;

        settings = {
            show_hidden = true;
            preview_images = true;
            preview_images_method = "kitty";
            save_console_history = true;
            max_console_history_size = 1000;
        };
    };
}
