{ pkgs, theme, ... }:
let
    colors = theme.base16;
    tabs = theme.tabs;
    window = theme.window;

    screenHeight = 1080;

    gapsOut = tabs.width + tabs.gap + tabs.margin;
    barX = gapsOut - window.border - theme.bar.width;
    barTop = gapsOut - window.border + tabs.maxHeight + window.gapsIn;
    barHeight = screenHeight - barTop - gapsOut;

    statsScript = pkgs.writeShellScript "eww-stats" (builtins.readFile ./scripts/stats.sh);

    ewwYuck = pkgs.writeText "eww.yuck" ''
        (defpoll stats
            :interval "2s"
            :initial '{"cpu":"0","temp":"0","ram":"0","vol":"0","bri":"0","time":"--:--","ts":"--","wifi":"0","bat":"0"}'
            "${statsScript}")

        (defwidget cell [text]
            (box :class "cell" :halign "center" :valign "center"
                (label :class "celltext" :angle 90 :text text)))

        (defwindow bar
            :monitor 0
            :stacking "fg"
            :exclusive false
            :focusable false
            :geometry (geometry
                :x ${toString barX}
                :y ${toString barTop}
                :width ${toString theme.bar.width}
                :height ${toString barHeight}
                :anchor "top left")
            (box :class "bar" :orientation "v" :space-evenly true
                (cell :text "CPU ''${stats.cpu}%")
                (cell :text "''${stats.temp}°")
                (cell :text "RAM ''${stats.ram}G")
                (cell :text "VOL ''${stats.vol}")
                (cell :text "BRI ''${stats.bri}")
                (cell :text "''${stats.time}")
                (cell :text "TS ''${stats.ts}")
                (cell :text "WIFI ''${stats.wifi}")
                (cell :text "BAT ''${stats.bat}%")))
    '';

    ewwScss = pkgs.writeText "eww.scss" ''
        * {
            all: unset;
        }

        .bar {
            background-color: transparent;
        }

        .celltext {
            color: #${colors.base02};
            font-family: "${theme.bar.font}";
            font-size: ${toString theme.bar.fontSize}pt;
        }
    '';

    config = pkgs.runCommand "eww-biggerworld" { } ''
        mkdir -p $out
        cp ${ewwYuck} $out/eww.yuck
        cp ${ewwScss} $out/eww.scss
    '';
in {
    home.packages = [ pkgs.eww ];

    xdg.configFile."eww".source = config;

    systemd.user.services.eww = {
        Unit = {
            Description = "eww status bar";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session.target" ];
        };

        Service = {
            ExecStart = "${pkgs.eww}/bin/eww daemon --no-daemonize";
            ExecStartPost = "${pkgs.eww}/bin/eww open bar";
            Restart = "on-failure";
            RestartSec = 2;
        };

        Install.WantedBy = [ "graphical-session.target" ];
    };
}
