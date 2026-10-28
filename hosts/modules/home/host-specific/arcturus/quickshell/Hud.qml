import QtQuick

Item {
    id: root

    property var s: ({})

    readonly property color red: Theme.accent
    readonly property color cyan: Theme.cyan
    readonly property string mono: Theme.fontFamily

    component Block: Item {
        id: blk
        property string title: ""
        property string value: ""
        property color tint: root.red
        property string diag: "tr-bl"

        readonly property int cut: Math.round(height / 4)

        implicitWidth: col.implicitWidth + 40
        implicitHeight: col.implicitHeight + 22

        Canvas {
            anchors.fill: parent
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const b = Theme.border / 2;
                const c = blk.cut;
                const x0 = b, y0 = b, x1 = width - b, y1 = height - b;

                ctx.beginPath();
                if (blk.diag === "tr-bl") {
                    ctx.moveTo(x0, y0);
                    ctx.lineTo(x1 - c, y0);
                    ctx.lineTo(x1, y0 + c);
                    ctx.lineTo(x1, y1);
                    ctx.lineTo(x0 + c, y1);
                    ctx.lineTo(x0, y1 - c);
                } else {
                    ctx.moveTo(x0 + c, y0);
                    ctx.lineTo(x1, y0);
                    ctx.lineTo(x1, y1 - c);
                    ctx.lineTo(x1 - c, y1);
                    ctx.lineTo(x0, y1);
                    ctx.lineTo(x0, y0 + c);
                }
                ctx.closePath();
                ctx.fillStyle = Qt.rgba(blk.tint.r, blk.tint.g, blk.tint.b, 0.08);
                ctx.fill();
                ctx.strokeStyle = blk.tint;
                ctx.lineWidth = Theme.border;
                ctx.stroke();
            }
        }

        Column {
            id: col
            anchors.centerIn: parent
            spacing: 1
            Text {
                text: blk.title
                color: Qt.rgba(blk.tint.r, blk.tint.g, blk.tint.b, 0.7)
                font.family: root.mono
                font.pointSize: 8
            }
            Text {
                text: blk.value
                color: blk.tint
                font.family: root.mono
                font.pointSize: 13
            }
        }
    }

    component Arm: Item {
        id: arm
        property string text: ""
        property color tint: root.red
        property bool toLeft: false
        property bool plain: false
        property int indent: 0

        implicitHeight: lbl.implicitHeight + (plain ? 2 : 10)
        implicitWidth: lbl.implicitWidth + (plain ? 2 : 46) + indent

        Canvas {
            anchors.fill: parent
            visible: !arm.plain
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const b = Theme.border / 2;
                const h = height - b;
                const c = Math.round(height / 3);
                const x0 = arm.toLeft ? b + arm.indent : b;
                const x1 = arm.toLeft ? width - b : width - b - arm.indent;

                ctx.beginPath();
                if (arm.toLeft) {
                    ctx.moveTo(x0 + c, b);
                    ctx.lineTo(x1, b);
                    ctx.lineTo(x1, h);
                    ctx.lineTo(x0, h);
                } else {
                    ctx.moveTo(x0, b);
                    ctx.lineTo(x1 - c, b);
                    ctx.lineTo(x1, h);
                    ctx.lineTo(x0, h);
                }
                ctx.closePath();
                ctx.fillStyle = Qt.rgba(arm.tint.r, arm.tint.g, arm.tint.b, 0.07);
                ctx.fill();
                ctx.strokeStyle = Qt.rgba(arm.tint.r, arm.tint.g, arm.tint.b, 0.75);
                ctx.lineWidth = Theme.border;
                ctx.stroke();
            }
        }

        Text {
            id: lbl
            anchors.verticalCenter: parent.verticalCenter
            x: arm.plain ? (arm.toLeft ? arm.width - implicitWidth : 0)
                         : (arm.toLeft ? arm.indent + 22 : 16)
            text: arm.text
            color: arm.tint
            font.family: root.mono
            font.pointSize: 9
            elide: Text.ElideRight
            width: arm.plain ? implicitWidth : Math.min(implicitWidth, arm.width - 46 - arm.indent)
        }
    }

    component ArmGroup: Column {
        property string heading: ""
        property var items: []
        property color tint: root.red
        property bool toLeft: false
        property bool rising: false
        property bool plain: false

        spacing: 5

        Text {
            text: parent.heading
            color: Qt.rgba(parent.tint.r, parent.tint.g, parent.tint.b, 0.55)
            font.family: root.mono
            font.pointSize: 8
            anchors.right: parent.toLeft ? parent.right : undefined
        }

        Repeater {
            model: parent.items
            Arm {
                required property int index
                required property var modelData
                text: modelData
                tint: parent.tint
                toLeft: parent.toLeft
                plain: parent.plain
                indent: parent.plain ? 0 : (parent.rising ? (parent.items.length - 1 - index) : index) * 16
                anchors.right: parent.toLeft ? parent.right : undefined
            }
        }
    }

    component Readout: Row {
        property string k: ""
        property string v: ""
        property color tint: root.red
        spacing: 8
        Text {
            text: parent.k
            color: Qt.rgba(parent.tint.r, parent.tint.g, parent.tint.b, 0.6)
            font.family: root.mono
            font.pointSize: 9
            width: parent.k.length > 7 ? 70 : 58
        }
        Text {
            text: parent.v
            color: parent.tint
            font.family: root.mono
            font.pointSize: 9
        }
    }

    property string clockText: ""
    property string dateText: ""

    Timer {
        interval: 5000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const d = new Date();
            root.clockText = Qt.formatDateTime(d, "HHmm");
            root.dateText = Qt.formatDateTime(d, "MM dd yy");
        }
    }

    Canvas {
        id: globe
        anchors.centerIn: parent
        width: Math.min(root.width * 0.46, root.height * 0.72)
        height: width

        readonly property var gauges: [
            { label: "CPU", v: root.s.cpu ?? 0 },
            { label: "MEM", v: root.s.mem ?? 0 },
            { label: "DSK", v: root.s.disk ?? 0 },
            { label: "BAT", v: root.s.bat ?? 0 }
        ]

        onGaugesChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const cx = width / 2, cy = height / 2, R = width / 2 - 6;
            ctx.lineWidth = 1;
            ctx.strokeStyle = root.red;

            ctx.globalAlpha = 0.9;
            ctx.beginPath();
            ctx.arc(cx, cy, R, 0, Math.PI * 2);
            ctx.stroke();

            ctx.globalAlpha = 0.26;
            for (let k = 1; k <= 4; k++) {
                const f = k / 5;
                const rr = R * Math.cos(Math.asin(f));
                for (let sg = -1; sg <= 1; sg += 2) {
                    ctx.beginPath();
                    ctx.ellipse(cx - rr, cy + sg * f * R - rr * 0.20, rr * 2, rr * 0.40);
                    ctx.stroke();
                }
            }
            ctx.beginPath();
            ctx.ellipse(cx - R, cy - R * 0.20, R * 2, R * 0.40);
            ctx.stroke();

            for (let m = 1; m < 6; m++) {
                const rx = Math.abs(R * Math.cos(Math.PI * m / 6));
                ctx.beginPath();
                ctx.ellipse(cx - rx, cy - R, rx * 2, R * 2);
                ctx.stroke();
            }

            const per = 18;
            const gap = 2;
            for (let q = 0; q < 4; q++) {
                const g = globe.gauges[q];
                const lit = Math.round(Math.max(0, Math.min(100, g.v)) / 100 * (per - gap));
                for (let t = 0; t < per - gap; t++) {
                    const idx = q * per + t;
                    const a = -Math.PI / 2 + idx * Math.PI * 2 / 72;
                    const on = t < lit;
                    ctx.globalAlpha = on ? 0.55 : 0.16;
                    ctx.strokeStyle = on ? root.cyan : root.red;
                    ctx.lineWidth = on ? 2 : 1;
                    const len = on ? 16 : 6;
                    ctx.beginPath();
                    ctx.moveTo(cx + Math.cos(a) * (R + 24), cy + Math.sin(a) * (R + 24));
                    ctx.lineTo(cx + Math.cos(a) * (R + 24 + len), cy + Math.sin(a) * (R + 24 + len));
                    ctx.stroke();
                }

                const mid = -Math.PI / 2 + (q * per + (per - gap) / 2) * Math.PI * 2 / 72;
                ctx.globalAlpha = 0.55;
                ctx.fillStyle = root.cyan;
                ctx.font = "11px '" + root.mono + "'";
                ctx.textAlign = "center";
                ctx.textBaseline = "middle";
                ctx.fillText(g.label + " " + Math.round(g.v) + "%",
                             cx + Math.cos(mid) * (R + 62),
                             cy + Math.sin(mid) * (R + 62));
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 2

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.clockText
            color: root.red
            font.family: Theme.displayFont
            font.pointSize: 54
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.dateText
            color: Qt.rgba(root.cyan.r, root.cyan.g, root.cyan.b, 0.8)
            font.family: Theme.displayFont
            font.pointSize: 18
        }
    }

    Block {
        anchors { left: parent.left; top: parent.top }
        tint: root.red
        diag: "tr-bl"
        title: "HOST"
        value: root.s.host ?? "--"
    }

    Block {
        anchors { right: parent.right; top: parent.top }
        tint: root.cyan
        diag: "tl-br"
        title: "TAILNET"
        value: (root.s.ts ?? "--") + ((root.s.exit ?? "") !== "" ? "  VIA " + root.s.exit : "")
    }

    property var items: ({})

    ArmGroup {
        anchors { left: parent.left; top: parent.top; topMargin: 76 }
        heading: "BUILD"
        items: root.items.build ?? []
        tint: root.cyan
        plain: true
    }

    ArmGroup {
        anchors { right: parent.right; top: parent.top; topMargin: 76 }
        heading: "FAILURES"
        items: root.items.fails ?? []
        tint: "#ffe44d"
        toLeft: true
        rising: true
    }

    ArmGroup {
        anchors { left: parent.left; bottom: parent.bottom; bottomMargin: 104 }
        heading: "WORK"
        items: root.items.work ?? []
        tint: root.red
    }

    ArmGroup {
        anchors { right: parent.right; bottom: parent.bottom; bottomMargin: 104 }
        heading: "TODO"
        items: root.items.todo ?? []
        tint: root.cyan
        toLeft: true
    }

    Column {
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
        spacing: 5

        Readout { k: "UPTIME"; v: root.s.uptime ?? "--" }
        Readout {
            k: "BATTERY"
            v: (root.s.bat ?? 0) + "%  " + (root.s.batstate ?? "")
            tint: (root.s.batstate ?? "") === "Discharging" && (root.s.bat ?? 100) <= 20 ? "#ffe44d" : root.red
        }
    }
}
