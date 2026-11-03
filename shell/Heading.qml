import QtQuick

Item {
    id: root
    property alias text: front.text
    property int size: 36
    property color color: Theme.ink
    property color ghostColor: Theme.inkSoft
    implicitWidth: front.implicitWidth + 4
    implicitHeight: front.implicitHeight + 4

    Text {
        x: Math.max(2, root.size / 14); y: Math.max(2, root.size / 14)
        text: front.text
        font: front.font
        color: root.ghostColor
        opacity: 0.45
    }
    Text {
        id: front
        color: root.color
        font.family: Theme.font
        font.pixelSize: root.size
        font.letterSpacing: 3
    }
}
