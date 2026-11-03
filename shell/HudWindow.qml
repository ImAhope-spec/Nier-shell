import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: win
    property real u: 1
    property bool atRight: false
    property bool atBottom: false
    property real mx: 0          // отступ от левого/правого края, px
    property real my: 0          // отступ от верхнего/нижнего края, px
    property bool panel: false   // рисовать сплошной фон
    property bool onTop: false
    property color panelColor: Theme.hudDark
    default property alias content: crt.content

    anchors { top: !win.atBottom; bottom: win.atBottom; left: !win.atRight; right: win.atRight }
    margins { top: win.my; bottom: win.my; left: win.mx; right: win.mx }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: win.onTop ? WlrLayer.Top : WlrLayer.Bottom
    WlrLayershell.namespace: "nier-hud"

    CrtPanel {
        id: crt
        anchors.fill: parent
        Rectangle { visible: win.panel; anchors.fill: parent; color: win.panelColor }
    }
}
