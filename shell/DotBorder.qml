import QtQuick

Item {
    id: root
    property bool lineOnTop: true
    property real k: 1                 // масштаб
    property real period: 77 * k
    property real inset: 70 * k
    property color color: Theme.ink
    height: 20 * k

    Rectangle {
        width: parent.width; height: Math.max(1, root.k)
        color: root.color
        y: root.lineOnTop ? 0 : root.height - height
    }
    Row {
        x: root.inset
        y: (root.lineOnTop ? 8 : 2) * root.k
        Repeater {
            model: Math.max(0, Math.ceil((root.width - root.inset * 2) / root.period))
            Item {
                width: root.period; height: 10 * root.k
                Rectangle { x: 0;             y: 3 * root.k; width: 11 * root.k; height: 4 * root.k; color: root.color }
                Rectangle { x: 30 * root.k;   y: 0;          width: 4 * root.k;  height: 4 * root.k; color: root.color }
                Rectangle { x: 46 * root.k;   y: 0;          width: 4 * root.k;  height: 4 * root.k; color: root.color }
                Rectangle { x: 38 * root.k;   y: 6 * root.k; width: 4 * root.k;  height: 4 * root.k; color: root.color }
            }
        }
    }
}
