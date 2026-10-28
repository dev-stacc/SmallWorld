{ pkgs, theme, ... }:
let
    colors = theme.base16;
    tabs = theme.tabs;

    labelScript = pkgs.writeShellScript "tab-labels" (builtins.readFile ./scripts/tab-labels.sh);

    themeQml = pkgs.writeText "Theme.qml" ''
        pragma Singleton

        import QtQuick
        import Quickshell

        Singleton {
            readonly property color background: "#${colors.base00}"
            readonly property color accent: "#${colors.base02}"
            readonly property color muted: "#${colors.base07}"
            readonly property string fontFamily: "${theme.fonts.readable}"
            readonly property int fontSize: ${toString tabs.fontSize}
            readonly property int tabWidth: ${toString tabs.width}
            readonly property int tabGap: ${toString tabs.gap}
            readonly property int slope: ${toString tabs.slope}
            readonly property int yOffset: ${toString tabs.yOffset}
            readonly property int refreshMs: ${toString tabs.refreshMs}
            readonly property int labelMs: ${toString tabs.labelMs}
            readonly property string labelScript: "${labelScript}"
            readonly property real inactiveOpacity: ${toString tabs.inactiveOpacity}
            readonly property int border: ${toString theme.window.border}
            readonly property int maxHeight: ${toString tabs.maxHeight}
        }
    '';

    config = pkgs.runCommand "quickshell-biggerworld" { } ''
        mkdir -p $out
        cp ${./shell.qml} $out/shell.qml
        cp ${./Tab.qml} $out/Tab.qml
        cp ${themeQml} $out/Theme.qml
        printf "singleton Theme 1.0 Theme.qml\\nTab 1.0 Tab.qml\\n" > $out/qmldir
    '';
in {
    home.packages = [ pkgs.quickshell ];

    xdg.configFile."quickshell/biggerworld".source = config;

    systemd.user.services.quickshell = {
        Unit = {
            Description = "quickshell window tabs";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session.target" ];
        };

        Service = {
            ExecStart = "${pkgs.quickshell}/bin/quickshell --config biggerworld";
            Restart = "on-failure";
            RestartSec = 2;
        };

        Install.WantedBy = [ "graphical-session.target" ];
    };
}
