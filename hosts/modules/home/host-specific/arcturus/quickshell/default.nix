{ pkgs, theme, ... }:
let
    colors = theme.base16;
    tabs = theme.tabs;
    window = theme.window;

    labelScript = pkgs.writeShellScript "tab-labels" (builtins.readFile ./scripts/tab-labels.sh);
    itemsScript = pkgs.writeShellScript "hud-items" (builtins.readFile ./scripts/hud-items.sh);
    idleScript = pkgs.writeShellScript "idle-stats" (builtins.readFile ./scripts/idle-stats.sh);

    themeQml = pkgs.writeText "Theme.qml" ''
        pragma Singleton

        import QtQuick
        import Quickshell

        Singleton {
            readonly property color background: "#${colors.base00}"
            readonly property color accent: "#${colors.base02}"
            readonly property color muted: "#${colors.base07}"
            readonly property color cyan: "#${colors.base03}"
            readonly property string fontFamily: "${theme.fonts.readable}"
            readonly property string displayFont: "${theme.bar.font}"
            readonly property int fontSize: ${toString tabs.fontSize}
            readonly property int tabWidth: ${toString tabs.width}
            readonly property int tabGap: ${toString tabs.gap}
            readonly property int slope: ${toString tabs.slope}
            readonly property int yOffset: ${toString tabs.yOffset}
            readonly property int refreshMs: ${toString tabs.refreshMs}
            readonly property int labelMs: ${toString tabs.labelMs}
            readonly property string labelScript: "${labelScript}"
            readonly property string idleScript: "${idleScript}"
            readonly property string itemsScript: "${itemsScript}"
            readonly property int gapsH: ${toString window.gapsH}
            readonly property int gapsV: ${toString window.gapsV}
            readonly property int animMs: ${toString theme.anim.ms}
            readonly property real inactiveOpacity: ${toString tabs.inactiveOpacity}
            readonly property int border: ${toString theme.window.border}
            readonly property int maxHeight: ${toString tabs.maxHeight}
        }
    '';

    config = pkgs.runCommand "quickshell-biggerworld" { } ''
        mkdir -p $out
        cp ${./shell.qml} $out/shell.qml
        cp ${./Tab.qml} $out/Tab.qml
        cp ${./Hud.qml} $out/Hud.qml
        cp ${themeQml} $out/Theme.qml
        printf "singleton Theme 1.0 Theme.qml\\nTab 1.0 Tab.qml\\nHud 1.0 Hud.qml\\n" > $out/qmldir
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
