{ config, lib, pkgs, fontName, fontSize, ... } : let
    colors = config.lib.stylix.colors;

    colorNames = [
        "base00" "base01" "base02" "base03" "base04" "base05"
        "base06" "base07" "base08" "base09" "base0A" "base0B"
        "base0C" "base0D" "base0E" "base0F"
    ];

    template = builtins.readFile ./homepage.html;

    homepageHtml = builtins.replaceStrings
        (map (n: "{{${n}}}") colorNames ++ [ "{{fontName}}" "{{fontSize}}" ])
        (map (n: "#${colors.${n}}") colorNames ++ [ fontName (toString fontSize) ])
        template;

    homepage = pkgs.writeText "homepage.html" homepageHtml;
in {
    home.file.".local/share/librewolf/homepage.html".source = homepage;

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
