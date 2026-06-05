{ pkgs, ... }: {
    programs.yt-dlp = {
        enable = true;
        package = pkgs.yt-dlp.override {
            javascriptSupport = false;
        };
        settings = {
            paths = "/home/anastasia/media/fresh-downloads";
            output = "%(title)s.%(ext)s";
            format = "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best";
            merge-output-format = "mp4";
            embed-thumbnail = true;
            add-metadata = true;
            audio-quality = 0;
        };
    };

    home.packages = [ pkgs.ffmpeg ];
}
