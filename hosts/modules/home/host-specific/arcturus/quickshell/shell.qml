import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

ShellRoot {
    id: shell

    property var procLabels: ({})
    property var idleStats: ({})
    property var hudItems: ({})
    property bool idle: false

    Process {
        id: labelProc
        command: [Theme.labelScript]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    shell.procLabels = JSON.parse(this.text);
                } catch (e) {
                }
            }
        }
    }

    Process {
        id: idleProc
        command: [Theme.idleScript]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    shell.idleStats = JSON.parse(this.text);
                } catch (e) {
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: if (!idleProc.running) idleProc.running = true
    }

    Process {
        id: itemsProc
        command: [Theme.itemsScript]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    shell.hudItems = JSON.parse(this.text);
                } catch (e) {
                }
            }
        }
    }

    Timer {
        interval: 30000
        running: shell.idle
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!itemsProc.running) itemsProc.running = true
    }

    Timer {
        interval: Theme.labelMs
        running: true
        repeat: true
        onTriggered: if (!labelProc.running) labelProc.running = true
    }

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

            readonly property int liveCount: {
                let n = 0;
                const vs = Hyprland.toplevels.values;
                for (let i = 0; i < vs.length; i++) {
                    const o = vs[i].lastIpcObject ?? ({});
                    if (o.mapped === true && o.hidden !== true && hmon !== null
                        && o.monitor === hmon.id && o.workspace !== undefined
                        && hmon.activeWorkspace !== null
                        && o.workspace.id === hmon.activeWorkspace.id)
                        n++;
                }
                return n;
            }

            Hud {
                opacity: panel.liveCount === 0 ? 1 : 0
                visible: opacity > 0
                onVisibleChanged: shell.idle = visible

                Behavior on opacity {
                    NumberAnimation { duration: Theme.animMs; easing.type: Easing.InOutQuad }
                }
                s: shell.idleStats
                items: shell.hudItems
                x: Theme.gapsH
                y: Theme.gapsV
                width: panel.width - Theme.gapsH * 2
                height: panel.height - Theme.gapsV * 2
            }

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
                    label: ov ? ov.label
                        : (shell.procLabels[String(ipc.pid)] ?? (ipc.class ?? "").toLowerCase())
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
