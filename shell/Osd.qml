import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import QtQuick

Scope {
    id: root
    readonly property var scr: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    readonly property real u: scr ? scr.height / 1512 : 1

    property bool shown: false
    property bool ready: false          // не показываем OSD, пока шелл только запустился
    property string mode: "slider"      // "slider" или "text"
    property string label: "Volume"
    property real value: 0              // 0..1
    property bool muted: false
    property string textValue: ""

    function show(name, v, isMuted) {
        if (!ready) return
        mode = "slider"
        label = name
        value = Math.max(0, Math.min(1, v))
        muted = isMuted
        shown = true
        hideTimer.restart()
    }
    function showText(name, text) {
        if (!ready) return
        mode = "text"
        label = name
        textValue = text
        muted = false
        shown = true
        hideTimer.restart()
    }

    Timer { interval: 3000; running: true; onTriggered: root.ready = true }
    Timer { id: hideTimer; interval: 1500; onTriggered: root.shown = false }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }
    readonly property var sinkAudio: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
    readonly property var srcAudio: Pipewire.defaultAudioSource ? Pipewire.defaultAudioSource.audio : null

    Connections {
        target: root.sinkAudio
        ignoreUnknownSignals: true
        function onVolumeChanged() { root.show("Volume", root.sinkAudio.volume, root.sinkAudio.muted) }
        function onMutedChanged()  { root.show("Volume", root.sinkAudio.volume, root.sinkAudio.muted) }
    }
    Connections {
        target: root.srcAudio
        ignoreUnknownSignals: true
        function onMutedChanged() { root.show("Microphone", root.srcAudio.volume, root.srcAudio.muted) }
    }

    property string lastLayout: ""
    function layoutCode(n) {
        const l = n.toLowerCase()
        if (l.indexOf("russian") >= 0) return "RU"
        if (l.indexOf("english") >= 0 || l.indexOf("us") >= 0) return "US"
        return n.slice(0, 2).toUpperCase()
    }
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name !== "activelayout") return
            const name = event.data.split(",").slice(1).join(",").trim()
            if (name === "" || name === root.lastLayout) return     // у нескольких клавиатур событие приходит дважды
            root.lastLayout = name
            root.showText("Layout", root.layoutCode(name) + "   " + name)
        }
    }

    function setBrightness(arg) {
        if (bproc.running) return
        bproc.command = ["brightnessctl", "-m", "-e4", "-n2", "set", arg]
        bproc.running = true
    }
    GlobalShortcut { appid: "nier"; name: "brightnessup";   description: "Brightness up";   onPressed: root.setBrightness("5%+") }
    GlobalShortcut { appid: "nier"; name: "brightnessdown"; description: "Brightness down"; onPressed: root.setBrightness("5%-") }
    Process {
        id: bproc
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",")
                const pct = parseFloat((f[3] || "").replace("%", ""))
                if (!isNaN(pct)) root.show("Brightness", pct / 100, false)
            }
        }
    }

    PanelWindow {
        id: win
        screen: root.scr
        visible: root.shown || bar.opacity > 0.01
        anchors { bottom: true }
        margins { bottom: 110 * root.u }
        implicitWidth: 760 * root.u
        implicitHeight: 64 * root.u
        color: "transparent"
        mask: Region {}                      // клики проходят сквозь OSD
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "nier-osd"

        Item {
            id: bar
            anchors.fill: parent
            opacity: root.shown ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 160 } }
            transform: Translate { y: root.shown ? 0 : 10 * root.u; Behavior on y { NumberAnimation { duration: 160 } } }

            CrtPanel {
                anchors.fill: parent
                aberration: 1.0

                Rectangle { anchors.fill: parent; color: Theme.hudDark; opacity: 0.97 }

                Rectangle {   // белый квадрат
                    x: 22 * root.u; anchors.verticalCenter: parent.verticalCenter
                    width: 24 * root.u; height: width
                    color: Theme.hudText
                }
                Text {
                    x: 66 * root.u; anchors.verticalCenter: parent.verticalCenter
                    text: root.label + (root.mode === "slider" && root.muted ? "  (Muted)" : "")
                    color: Theme.hudText
                    font.family: Theme.font; font.pixelSize: 28 * root.u; font.letterSpacing: 2
                }

                // раскладка: код и название языка
                Text {
                    visible: root.mode === "text"
                    anchors.right: parent.right; anchors.rightMargin: 28 * root.u
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.textValue
                    color: Theme.hudText
                    font.family: Theme.font; font.pixelSize: 30 * root.u; font.letterSpacing: 3
                }

                // шкала: пройденные чёрточки, маркер с засечками, дальше точки
                Item {
                    id: ticks
                    visible: root.mode === "slider"
                    x: 330 * root.u; width: parent.width - x - 96 * root.u; height: parent.height
                    readonly property int n: 30
                    readonly property int k: Math.round((root.muted ? 0 : root.value) * n)
                    Repeater {
                        model: ticks.n + 1
                        Item {
                            x: index * (ticks.width / ticks.n)
                            width: 4 * root.u; height: ticks.height
                            Rectangle {   // пройдено
                                visible: index < ticks.k
                                anchors.centerIn: parent
                                width: 3 * root.u; height: 22 * root.u
                                color: Theme.hudText
                            }
                            Item {        // маркер
                                visible: index === ticks.k
                                anchors.fill: parent
                                Rectangle { anchors.centerIn: parent; width: 4 * root.u; height: 30 * root.u; color: Theme.hudText }
                                Rectangle { x: 0; y: parent.height / 2 - 26 * root.u; width: 3 * root.u; height: 4 * root.u; color: Theme.hudText }
                                Rectangle { x: 0; y: parent.height / 2 + 22 * root.u; width: 3 * root.u; height: 4 * root.u; color: Theme.hudText }
                            }
                            Rectangle {   // осталось
                                visible: index > ticks.k
                                anchors.centerIn: parent
                                width: 3 * root.u; height: width
                                color: Theme.hudText; opacity: 0.85
                            }
                        }
                    }
                }

                Text {
                    visible: root.mode === "slider"
                    anchors.right: parent.right; anchors.rightMargin: 24 * root.u
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.muted ? "--" : Math.round(root.value * 100)
                    color: Theme.hudText; opacity: 0.8
                    font.family: Theme.font; font.pixelSize: 20 * root.u; font.letterSpacing: 1
                }
            }
        }
    }
}
