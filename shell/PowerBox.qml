import QtQuick

Item {
    id: box
    property real u: 1
    property bool plain: false
    property bool selected: false
    property string kind: "lock"
    property string title: ""
    property string line1: ""
    property string line2: ""
    signal hovered()
    signal clicked()

    Rectangle {
        anchors.fill: parent
        color: box.selected ? Theme.ink : Theme.panel
        opacity: box.selected ? 1.0 : 0.82
    }
    // боковые планки: у выбранного светлые, у остальных тёмные
    Rectangle { x: 22 * box.u;              width: 4 * box.u; height: parent.height; color: box.selected ? Theme.hudText : Theme.ink }
    Rectangle { x: parent.width - 26 * box.u; width: 4 * box.u; height: parent.height; color: box.selected ? Theme.hudText : Theme.ink }

    Text {
        visible: box.plain
        anchors.centerIn: parent
        text: box.title
        color: box.selected ? Theme.paper : Theme.ink
        font.family: Theme.font; font.pixelSize: 34 * box.u; font.letterSpacing: 3
    }

    Item {
        visible: !box.plain
        anchors.fill: parent
        Rectangle {
            x: 78 * box.u; anchors.verticalCenter: parent.verticalCenter
            width: 84 * box.u; height: 72 * box.u
            color: box.selected ? Theme.hudText : Theme.barBeige
            PowerGlyph {
                anchors.centerIn: parent
                width: 52 * box.u; height: 52 * box.u
                kind: box.kind
                tint: box.selected ? Theme.hudDarker : Theme.ink
            }
        }
        Column {
            x: 186 * box.u; anchors.verticalCenter: parent.verticalCenter
            spacing: 2 * box.u
            Text {
                text: box.title
                color: box.selected ? Theme.paper : Theme.ink
                font.family: Theme.font; font.pixelSize: 34 * box.u; font.letterSpacing: 2
            }
            Text {
                text: box.line1
                color: box.selected ? Theme.paper : Theme.ink
                font.family: Theme.font; font.pixelSize: 19 * box.u; font.letterSpacing: 1
            }
            Text {
                text: box.line2
                visible: text !== ""
                color: box.selected ? Theme.paper : Theme.inkSoft
                font.family: Theme.font; font.pixelSize: 19 * box.u; font.letterSpacing: 1
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onPositionChanged: m => box.hovered()
        onClicked: box.clicked()
    }
}
