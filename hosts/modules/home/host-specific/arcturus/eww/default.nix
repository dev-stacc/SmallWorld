{ pkgs, theme, ... }:
let
    colors = theme.base16;
    tabs = theme.tabs;
    window = theme.window;

    screenHeight = 1080;

    barX = window.gapsH - theme.bar.width;
    barTop = window.gapsV + tabs.maxHeight + window.gapsIn;
    barHeight = screenHeight - barTop - window.gapsV;

    statsScript = pkgs.writeShellScript "eww-stats" (builtins.readFile ./scripts/stats.sh);

    ewwYuck = pkgs.writeText "eww.yuck" ''
        (defpoll stats
            :interval "2s"
            :initial '{"cpu":"0","temp":"0","fan":"0","bat":0,"batstate":"Unknown","ram":"0","wifi":"0","ts":"--","bt":"--","ws":"-","time":"--:--","vol":"0","bri":"0"}'
            "${statsScript}")

        (deflisten blink :initial "1"
            "while :; do echo 1; sleep 0.6; echo 0; sleep 0.6; done")

        (defwidget cell [text]
            (box :class "cell" :halign "center" :valign "center"
                (label :class "celltext" :angle 90 :text text)))

        (defwidget battery [pct state]
            (box :class "cell"
                 :orientation "v"
                 :space-evenly false
                 :halign "center"
                 :valign "center"
                 :spacing 4
                (label :class "ind ''${blink == "1" ? (state != "Discharging" ? "ok" : (pct <= 20 ? "low" : "draining")) : "off"}"
                       :angle 90
                       :text "▪")
                (label :class "celltext" :angle 90 :text "BAT ''${pct}%")))

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
            (box :class "bar"
                 :orientation "v"
                 :space-evenly false
                 :spacing ${toString theme.bar.spacing}
                 :valign "center"
                (battery :pct {stats.bat} :state {stats.batstate})
                (cell :text "''${stats.time}")
                (cell :text "TS ''${stats.ts}")
                (cell :text "BT ''${stats.bt}")
                (cell :text "VOL ''${stats.vol}")
                (cell :text "BRI ''${stats.bri}")
                (cell :text "WIFI ''${stats.wifi}")
                (cell :text "RAM ''${stats.ram}G")
                (cell :text "FAN ''${stats.fan}")
                (cell :text "''${stats.temp}°")
                (cell :text "CPU ''${stats.cpu}%")
                (cell :text "WS ''${stats.ws}")))
    '';

    ewwScss = pkgs.writeText "eww.scss" ''
        * {
            all: unset;
        }

        .bar {
            background-color: transparent;
        }

        .celltext,
        .ind {
            font-family: "${theme.bar.font}";
            font-size: ${toString theme.bar.fontSize}pt;
        }

        .celltext {
            color: #${colors.base02};
        }

        .ind.ok {
            color: #${colors.base08};
        }

        .ind.off {
            color: #${colors.base01};
        }

        .ind.draining {
            color: #${colors.base03};
        }

        .ind.low {
            color: #${colors.base04};
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
