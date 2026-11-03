import QtQuick

// Левый верхний угол: заряд (как полоска HP), загрузка CPU и GPU
Item {
    id: root
    property real u: 1
    property real bat: 1
    property bool hasBat: false

    readonly property real bx: 17 * u
    readonly property real bw: 570 * u
    readonly property real lx: bx + bw + 8 * u

    // декоративные квадраты над полоской
    Rectangle { x: root.bx; y: 0; width: 15 * root.u; height: 15 * root.u; color: Theme.barBeige }
    Rectangle { x: root.bx + 554 * root.u; y: 0; width: 15 * root.u; height: 15 * root.u; color: Theme.barBeige }

    Rectangle {
        x: root.bx; y: 22 * root.u; width: root.bw; height: 31 * root.u
        color: Theme.ink
        Rectangle {
            width: parent.width * (root.hasBat ? root.bat : 1)
            height: parent.height
            color: (root.hasBat && root.bat < 0.15) ? Theme.accent : Theme.barBeige
        }
    }
    Text {
        x: root.lx; y: 22 * root.u + (31 * root.u - height) / 2
        text: root.hasBat ? Math.round(root.bat * 100) + "%" : "AC"
        color: Theme.ink
        font.family: Theme.font; font.pixelSize: 17 * root.u; font.letterSpacing: 1
    }

    Rectangle { x: root.bx; y: 64 * root.u; width: root.bw; height: 5 * root.u; color: Theme.barGrey; opacity: 0.35 }
    Rectangle { x: root.bx; y: 64 * root.u; width: root.bw * Stats.cpu; height: 5 * root.u; color: Theme.barGrey }
    Text {
        x: root.lx; y: 66.5 * root.u - height / 2
        text: "CPU " + Math.round(Stats.cpu * 100) + "%"
        color: Theme.ink
        font.family: Theme.font; font.pixelSize: 14 * root.u; font.letterSpacing: 1
    }

    Rectangle { x: root.bx; y: 82 * root.u; width: root.bw; height: 8 * root.u; color: Theme.barBeige; opacity: 0.45 }
    Rectangle { x: root.bx; y: 82 * root.u; width: root.bw * Math.max(0, Stats.gpu); height: 8 * root.u; color: Theme.barBeige }
    Rectangle {   // кружок слева
        x: 0; y: 86 * root.u - 9 * root.u; width: 18 * root.u; height: 18 * root.u; radius: width / 2
        color: "transparent"; border.width: 1; border.color: Theme.barBeige
    }
    Rectangle {   // точка справа
        x: root.lx; y: 86 * root.u - 5 * root.u; width: 10 * root.u; height: 10 * root.u; radius: width / 2
        color: Theme.barBeige
    }
    Text {
        x: root.lx + 16 * root.u; y: 86 * root.u - height / 2
        text: Stats.gpu < 0 ? "GPU N/A" : "GPU " + Math.round(Stats.gpu * 100) + "%"
        color: Theme.ink
        font.family: Theme.font; font.pixelSize: 14 * root.u; font.letterSpacing: 1
    }
}
