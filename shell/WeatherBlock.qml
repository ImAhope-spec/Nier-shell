import QtQuick

Item {
    id: root
    property real u: 1

    Text {
        x: 26 * root.u; anchors.verticalCenter: parent.verticalCenter
        text: isNaN(Weather.temp) ? "--" : Math.round(Weather.temp) + "\u00b0"
        color: Theme.hudText
        font.family: Theme.font; font.pixelSize: 54 * root.u; font.letterSpacing: 2
    }
    Column {
        anchors.right: parent.right; anchors.rightMargin: 24 * root.u
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4 * root.u
        Text {
            anchors.right: parent.right
            text: Weather.text
            color: Theme.hudText
            font.family: Theme.font; font.pixelSize: 24 * root.u; font.letterSpacing: 3
        }
        Text {
            anchors.right: parent.right
            text: (Location.city !== "" ? Location.city.toUpperCase() + "  " : "") + "WIND " + Weather.wind.toFixed(1) + " M/S"
            color: Theme.hudText; opacity: 0.7
            font.family: Theme.font; font.pixelSize: 14 * root.u; font.letterSpacing: 2
        }
    }
}
