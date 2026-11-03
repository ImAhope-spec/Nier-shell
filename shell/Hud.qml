import Quickshell
import Quickshell.Services.UPower
import QtQuick

Scope {
    id: root
    readonly property var bat: UPower.displayDevice
    readonly property bool hasBat: bat && bat.isPresent
    // если проценты окажутся 0..100, а не 0..1, убери "/ 1" -> "/ 100"
    readonly property real batFrac: hasBat ? Math.max(0, Math.min(1, bat.percentage / 1)) : 1

    Variants {
        model: Quickshell.screens
        delegate: Scope {
            id: ps
            required property var modelData
            readonly property real u: modelData.height / 1512   // макет рисовался на 1512 по высоте

            // левый верхний: заряд / CPU / GPU
            HudWindow {
                screen: ps.modelData; u: ps.u
                mx: 20 * ps.u; my: 15 * ps.u
                implicitWidth: 700 * ps.u; implicitHeight: 100 * ps.u
                Vitals { anchors.fill: parent; u: ps.u; bat: root.batFrac; hasBat: root.hasBat }
            }

            // под полоской: воркспейсы
            HudWindow {
                screen: ps.modelData; u: ps.u
                mx: 20 * ps.u; my: 122 * ps.u
                implicitWidth: 700 * ps.u; implicitHeight: 76 * ps.u
                WorkspaceBar { anchors.fill: parent; u: ps.u }
            }

            // правый верхний: большие часы
            HudWindow {
                screen: ps.modelData; u: ps.u
                atRight: true; mx: 60 * ps.u; my: 59 * ps.u
                implicitWidth: 428 * ps.u; implicitHeight: 352 * ps.u
                panel: true
                ClockBlock { anchors.fill: parent; u: ps.u }
            }

            // правый столбец, под часами: что играет (только если есть плеер)
            HudWindow {
                screen: ps.modelData; u: ps.u
                atRight: true; mx: 60 * ps.u; my: 430 * ps.u
                implicitWidth: 428 * ps.u; implicitHeight: 76 * ps.u
                panel: true
                visible: Media.active
                NowPlaying { anchors.fill: parent; u: ps.u }
            }

            // правый нижний: погода
            HudWindow {
                screen: ps.modelData; u: ps.u
                atRight: true; atBottom: true; mx: 60 * ps.u; my: 545 * ps.u
                implicitWidth: 428 * ps.u; implicitHeight: 94 * ps.u
                panel: true
                WeatherBlock { anchors.fill: parent; u: ps.u }
            }

            // правый нижний: миникарта
            HudWindow {
                screen: ps.modelData; u: ps.u
                atRight: true; atBottom: true; mx: 60 * ps.u; my: 42 * ps.u
                implicitWidth: 428 * ps.u; implicitHeight: 455 * ps.u
                MiniMap { anchors.fill: parent; u: ps.u }
            }
        }
    }
}
