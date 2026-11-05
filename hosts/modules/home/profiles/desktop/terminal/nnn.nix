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

    programs.nnn = {
        enable = true;
        package = pkgs.nnn;

        extraPackages = tools;

        plugins = {
            src = pkgs.nnn.src + "/plugins";
            mappings.p = "preview-tui";
        };
    };

    home.sessionVariables = {
        NNN_OPTS = "ce";
        NNN_FIFO = "/tmp/nnn.fifo";
    };
}
