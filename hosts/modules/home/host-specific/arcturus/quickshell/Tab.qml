import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property string label: ""
    property string side: "left"
    property bool active: false

    readonly property color body: active ? Theme.accent : Qt.rgba(Theme.muted.r, Theme.muted.g, Theme.muted.b, Theme.inactiveOpacity)
    readonly property color ink: Theme.background
    readonly property int cut: Math.min(Theme.slope, Math.floor(root.height / 2))

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.body
            strokeWidth: -1
            capStyle: ShapePath.FlatCap
            joinStyle: ShapePath.MiterJoin

            startX: 0
            startY: root.side === "left" ? root.cut : 0

            PathPolyline {
                path: root.side === "left"
                    ? [
                        Qt.point(0, root.cut),
                        Qt.point(root.width, 0),
                        Qt.point(root.width, root.height),
                        Qt.point(0, root.height - root.cut),
                        Qt.point(0, root.cut)
                      ]
                    : [
                        Qt.point(0, 0),
                        Qt.point(root.width, root.cut),
                        Qt.point(root.width, root.height - root.cut),
                        Qt.point(0, root.height),
                        Qt.point(0, 0)
                      ]
            }
        }
    }

    Text {
        anchors.centerIn: parent
        rotation: root.side === "left" ? -90 : 90
        text: root.label
        color: root.ink
        font.family: Theme.fontFamily
        font.pointSize: Theme.fontSize
        elide: Text.ElideRight
        width: root.height - root.cut * 2
        horizontalAlignment: Text.AlignHCenter
    }
}
