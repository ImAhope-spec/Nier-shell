import QtQuick

Item {
    id: root
    property real u: 1

    MediaGlyph {
        x: 24 * root.u; anchors.verticalCenter: parent.verticalCenter
        width: 22 * root.u; height: 24 * root.u
        kind: Media.playing ? "play" : "pause"
        tint: Theme.hudText
        opacity: Media.playing ? 1 : 0.6
    }
    Column {
        x: 66 * root.u; anchors.verticalCenter: parent.verticalCenter
        width: parent.width - 90 * root.u
        spacing: 3 * root.u
        Text {
            text: "NOW PLAYING"
            color: Theme.hudText; opacity: 0.6
            font.family: Theme.font; font.pixelSize: 12 * root.u; font.letterSpacing: 3
        }
        Text {
            width: parent.width
            text: (Media.artist !== "" ? Media.artist + " \u2014 " : "") + Media.title
            elide: Text.ElideRight
            color: Theme.hudText
            font.family: Theme.font; font.pixelSize: 19 * root.u; font.letterSpacing: 1
        }
    }
    MouseArea { anchors.fill: parent; onClicked: Media.open = !Media.open }
}
