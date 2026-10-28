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
            width: 58
        }
        Text {
            text: parent.v
            color: parent.tint
            font.family: root.mono
            font.pointSize: 9
        }
    }

    Canvas {
        id: globe
        anchors.centerIn: parent
        width: Math.min(root.width * 0.46, root.height * 0.72)
        height: width

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

            ctx.globalAlpha = 0.45;
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

            ctx.globalAlpha = 0.8;
            ctx.strokeStyle = root.cyan;
            for (let t = 0; t < 72; t++) {
                const a = t * Math.PI / 36;
                const len = (t % 6 === 0) ? 10 : 4;
                ctx.beginPath();
                ctx.moveTo(cx + Math.cos(a) * (R + 12), cy + Math.sin(a) * (R + 12));
                ctx.lineTo(cx + Math.cos(a) * (R + 12 + len), cy + Math.sin(a) * (R + 12 + len));
                ctx.stroke();
            }
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

    Column {
        anchors { left: parent.left; bottom: parent.bottom }
        spacing: 5
        Text {
            text: "SYSTEM"
            color: Qt.rgba(root.red.r, root.red.g, root.red.b, 0.6)
            font.family: root.mono
            font.pointSize: 8
        }
        Readout { k: "UPTIME"; v: root.s.uptime ?? "--" }
        Readout { k: "CPU"; v: (root.s.cpu ?? 0) + "%  " + (root.s.temp ?? 0) + "°" }
        Readout { k: "MEMORY"; v: (root.s.memused ?? "--") + "G  " + (root.s.mem ?? 0) + "%" }
        Readout { k: "DISK"; v: (root.s.disk ?? 0) + "%" }
        Readout {
            k: "BATTERY"
            v: (root.s.bat ?? 0) + "%  " + (root.s.batstate ?? "")
            tint: (root.s.batstate ?? "") === "Discharging" && (root.s.bat ?? 100) <= 20 ? "#ffe44d" : root.red
        }
    }

    Column {
        anchors { right: parent.right; bottom: parent.bottom }
        spacing: 5
        Text {
            text: "KEYS"
            color: Qt.rgba(root.cyan.r, root.cyan.g, root.cyan.b, 0.6)
            font.family: root.mono
            font.pointSize: 8
        }
        Readout { k: "SUPER ↵"; v: "terminal"; tint: root.cyan }
        Readout { k: "SUPER D"; v: "apps"; tint: root.cyan }
        Readout { k: "SUPER T"; v: "browser"; tint: root.cyan }
        Readout { k: "SUPER E"; v: "files"; tint: root.cyan }
        Readout { k: "SUPER N"; v: "network"; tint: root.cyan }
        Readout { k: "SUPER Q"; v: "close"; tint: root.cyan }
    }
}
