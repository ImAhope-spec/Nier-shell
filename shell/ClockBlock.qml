import Quickshell
import QtQuick

Item {
    id: root
    property real u: 1

    SystemClock { id: clk; precision: SystemClock.Seconds }

    readonly property real cell: (width - 52 * u) / 25     // 25 клеток в ряду HH:MM
    readonly property string hh: Qt.formatTime(clk.date, "HH")
    readonly property string mm: Qt.formatTime(clk.date, "mm")

    // шапка как у панели Status
    Rectangle {
        id: head
        width: parent.width; height: 46 * root.u
        color: Theme.hudDarker
        Text {
            x: 22 * root.u; anchors.verticalCenter: parent.verticalCenter
            text: "TIME"
            color: Theme.hudText
            font.family: Theme.font; font.pixelSize: 22 * root.u; font.letterSpacing: 4
        }
        Text {
            anchors.right: parent.right; anchors.rightMargin: 22 * root.u
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDate(clk.date, "dd.MM.yyyy")
            color: Theme.hudText
            font.family: Theme.font; font.pixelSize: 20 * root.u; font.letterSpacing: 2
        }
    }

    Row {
        x: 26 * root.u; y: head.height + 38 * root.u
        spacing: root.cell
        DotDigit { ch: root.hh.charAt(0); cell: root.cell }
        DotDigit { ch: root.hh.charAt(1); cell: root.cell }
        Item {   // двоеточие мигает
            width: root.cell * 0.8; height: 7 * root.cell
            opacity: clk.date.getSeconds() % 2 === 0 ? 1 : 0.25
            Rectangle { y: 2 * root.cell; width: parent.width; height: width; color: Theme.hudText }
            Rectangle { y: 4 * root.cell; width: parent.width; height: width; color: Theme.hudText }
        }
        DotDigit { ch: root.mm.charAt(0); cell: root.cell }
        DotDigit { ch: root.mm.charAt(1); cell: root.cell }
    }

    Heading {
        x: 26 * root.u; y: head.height + 38 * root.u + 7 * root.cell + 22 * root.u
        text: Qt.formatDate(clk.date, "dddd").toUpperCase()
        size: 30 * root.u
        color: Theme.hudText
        ghostColor: Theme.hudDarker
    }

    // секунды: 12 клеток по 5 секунд
    Row {
        x: 30 * root.u; y: parent.height - 72 * root.u
        spacing: 16 * root.u
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatTime(clk.date, "ss")
            color: Theme.hudText
            font.family: Theme.font; font.pixelSize: 22 * root.u; font.letterSpacing: 2
        }
        SegBar {
            anchors.verticalCenter: parent.verticalCenter
            count: 12; filled: Math.floor(clk.date.getSeconds() / 5) + 1
            color: Theme.hudText; cell: 14 * root.u
        }
    }

    DotBorder {
        x: 0; width: parent.width; y: parent.height - 30 * root.u
        lineOnTop: false; color: Theme.hudText; inset: 22
    }
}
