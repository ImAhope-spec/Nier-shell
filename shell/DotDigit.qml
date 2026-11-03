import QtQuick

Item {
    id: root
    property string ch: "0"
    property real cell: 15
    property color color: Theme.hudText

    readonly property var font: ({
        "0": ["01110","10001","10011","10101","11001","10001","01110"],
        "1": ["00100","01100","00100","00100","00100","00100","01110"],
        "2": ["01110","10001","00001","00010","00100","01000","11111"],
        "3": ["11110","00001","00001","01110","00001","00001","11110"],
        "4": ["00010","00110","01010","10010","11111","00010","00010"],
        "5": ["11111","10000","11110","00001","00001","10001","01110"],
        "6": ["00110","01000","10000","11110","10001","10001","01110"],
        "7": ["11111","00001","00010","00100","01000","01000","01000"],
        "8": ["01110","10001","10001","01110","10001","10001","01110"],
        "9": ["01110","10001","10001","01111","00001","00010","01100"]
    })
    readonly property var pat: font[ch] ?? font["0"]

    width: 5 * cell - cell * 0.2
    height: 7 * cell - cell * 0.2

    Repeater {
        model: 35
        Rectangle {
            readonly property int gx: index % 5
            readonly property int gy: Math.floor(index / 5)
            readonly property bool on: root.pat[gy].charAt(gx) === "1"
            x: gx * root.cell; y: gy * root.cell
            width: root.cell * 0.8; height: root.cell * 0.8
            color: on ? root.color : "transparent"
            border.width: on ? 0 : 1
            border.color: root.color
            opacity: on ? 1 : 0.2
        }
    }
}
