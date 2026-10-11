{ pkgs, tailnet, theme, ... } : let
    colors = theme.base16;

    searxPort = 12346;
    localTimeout = 250;
    clusterTimeout = 800;

    colorNames = [
        "base00" "base01" "base02" "base03" "base04" "base05"
        "base06" "base07" "base08" "base09" "base0A" "base0B"
        "base0C" "base0D" "base0E" "base0F"
    ];

    themed = file: builtins.replaceStrings
        (map (n: "{{${n}}}") colorNames ++ [
            "{{fontName}}"
            "{{fontSize}}"
            "{{localOrigin}}"
            "{{clusterOrigin}}"
            "{{localTimeout}}"
            "{{clusterTimeout}}"
        ])
        (map (n: "#${colors.${n}}") colorNames ++ [
            theme.fonts.monospace
            (toString theme.fonts.sizes.terminal)
            "http://127.0.0.1:${toString searxPort}"
            "https://search.${tailnet.domain}"
            (toString localTimeout)
            (toString clusterTimeout)
        ])
        (builtins.readFile file);

    homepage = pkgs.writeText "homepage.html" (themed ./homepage.html);

    searchPage = pkgs.writeText "search.html" (themed ./search.html);
in {
    home.file = {
        ".local/share/librewolf/homepage.html".source = homepage;
        ".local/share/librewolf/search.html".source = searchPage;
    };

    systemd.user.services.librewolf-homepage = {
        Unit = {
            Description = "Static server for LibreWolf custom homepage";
        };
        Service = {
            ExecStart = "${pkgs.darkhttpd}/bin/darkhttpd /home/anastasia/.local/share/librewolf --port 12345 --addr 127.0.0.1";
            Restart = "on-failure";
        };
        Install = {
            WantedBy = [ "default.target" ];
        };
    };
}
