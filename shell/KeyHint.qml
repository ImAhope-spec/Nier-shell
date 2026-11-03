import QtQuick

Row {
    property string key: ""
    property string label: ""
    spacing: 10
    Rectangle {
        width: Math.max(26, k.implicitWidth + 14); height: 26
        color: Theme.ink
        radius: 2
        anchors.verticalCenter: parent.verticalCenter
        Text {
            id: k
            anchors.centerIn: parent
            text: key
            color: Theme.paper
            font.family: Theme.font; font.pixelSize: 14; font.bold: true
        }
    }
    Text {
        text: label
        color: Theme.ink
        anchors.verticalCenter: parent.verticalCenter
        font.family: Theme.font; font.pixelSize: 22; font.letterSpacing: 2
    }
}
