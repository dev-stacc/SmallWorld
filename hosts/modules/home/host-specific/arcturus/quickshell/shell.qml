import QtQuick
import Quickshell
import Quickshell.Hyprland

ShellRoot {
    id: shell

    readonly property var tabOverrides: ({
        "kitty-launcher": { "label": "apps", "scale": 0.5 },
        "kitty-control": { "label": "net", "scale": 0.5 }
    })

    Timer {
        interval: Theme.refreshMs
        running: true
        repeat: true
        onTriggered: Hyprland.refreshToplevels()
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel
            required property var modelData

            screen: modelData
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            aboveWindows: true
            focusable: false
            mask: Region {}

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            readonly property var hmon: Hyprland.monitorFor(modelData)

            Repeater {
                model: Hyprland.toplevels

                Tab {
                    id: tab
                    required property var modelData

                    readonly property var ipc: modelData.lastIpcObject ?? ({})
                    readonly property bool onScreen: ipc.mapped === true
                        && ipc.hidden !== true
                        && panel.hmon !== null
                        && ipc.monitor === panel.hmon.id
                        && ipc.workspace !== undefined
                        && panel.hmon.activeWorkspace !== null
                        && ipc.workspace.id === panel.hmon.activeWorkspace.id
                    readonly property bool anyFullscreen: (ipc.fullscreen ?? 0) > 0

                    readonly property int wx: (ipc.at ?? [0, 0])[0] - panel.hmon.x
                    readonly property int wy: (ipc.at ?? [0, 0])[1] - panel.hmon.y
                    readonly property int ww: (ipc.size ?? [0, 0])[0]
                    readonly property int wh: (ipc.size ?? [0, 0])[1]

                    readonly property var ov: shell.tabOverrides[ipc.title ?? ""] ?? null

                    side: (wx + ww / 2) < (panel.hmon.width / 2) ? "left" : "right"
                    label: ov ? ov.label : (ipc.class ?? "").toLowerCase()
                    active: modelData.activated

                    visible: onScreen && !anyFullscreen && ww > 0
                    x: side === "left" ? wx - Theme.tabWidth - Theme.border : wx + ww + Theme.border
                    y: wy - Theme.border + Theme.yOffset
                    width: Theme.tabWidth
                    height: Math.min((wh + Theme.border * 2) * (ov ? ov.scale : 1), Theme.maxHeight)
                }
            }
        }
    }
}
