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

    programs.nnn = {
        enable = true;
        package = pkgs.nnn;
        options = {
            # Basic settings for nnn
            NNN_BMS = "";
            NNN_FIFO = "/tmp/nnn.fifo";
            NNN_PLUG = "";
            NNN_TRASH = "";
            NNN_OPENER = "";
            NNN_OPTS = "ce";
        };
    };
}