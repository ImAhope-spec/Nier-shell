import Quickshell.Hyprland
import QtQuick

Item {
    id: root
    property real u: 1
    readonly property real pitch: 57 * u
    readonly property real sz: 26 * u

    Repeater {
        model: 10
        Item {
            id: cell
            readonly property int ws: index + 1
            readonly property bool focused: Hyprland.focusedWorkspace?.id === ws
            readonly property bool exists: Hyprland.workspaces.values.some(w => w.id === ws)
            x: 17 * root.u + index * root.pitch
            width: root.sz; height: parent.height

            Rectangle {   // ромбик-указатель над активным
                visible: cell.focused
                x: (root.sz - width) / 2; y: 2 * root.u
                width: 10 * root.u; height: width; rotation: 45
                color: Theme.ink
            }
            Rectangle {
                y: 16 * root.u
                width: root.sz; height: root.sz
                color: cell.focused ? Theme.ink : "transparent"
                border.width: Math.max(1, 2 * root.u)
                border.color: (cell.exists || cell.focused) ? Theme.ink : Theme.inkSoft
                opacity: (cell.exists || cell.focused) ? 1 : 0.7
                Rectangle {
                    visible: cell.exists && !cell.focused
                    anchors.centerIn: parent
                    width: 8 * root.u; height: width; color: Theme.ink
                }
            }
            Text {
                y: 16 * root.u + root.sz + 4 * root.u
                x: (root.sz - width) / 2
                text: cell.ws % 10
                color: cell.focused ? Theme.ink : Theme.inkSoft
                font.family: Theme.font; font.pixelSize: 13 * root.u; font.letterSpacing: 1
            }
            MouseArea {
                anchors.fill: parent
                onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + cell.ws + " })")
            }
        }
    }
}
