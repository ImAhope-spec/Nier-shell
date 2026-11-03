import QtQuick

Row {
    id: bar
    property int count: 10
    property int filled: 0
    property color color: Theme.ink
    property real cell: 12
    spacing: cell / 2
    Repeater {
        model: bar.count
        Rectangle {
            width: bar.cell; height: bar.cell
            color: index < bar.filled ? bar.color : "transparent"
            border.width: 1
            border.color: bar.color
        }
    }
}
