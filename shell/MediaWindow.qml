import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

Scope {
    id: root

    GlobalShortcut {
        appid: "nier"
        name: "media"
        description: "Toggle media player"
        onPressed: Media.open = !Media.open
    }

    PanelWindow {
        id: win
        visible: Media.open
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "nier-media"
        WlrLayershell.keyboardFocus: Media.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        readonly property real u: Math.min(width / 2419, height / 1512)

        CrtPanel {
            anchors.fill: parent
            aberration: 1.1

            Rectangle { anchors.fill: parent; color: Theme.paper }

            // холст 2419x1512, по центру
            Item {
                id: canvas
                width: 2419 * win.u; height: 1512 * win.u
                anchors.centerIn: parent

                // бордюры сверху и снизу
                DotBorder { x: 0; y: 118 * win.u; width: parent.width; k: win.u; lineOnTop: true }
                DotBorder { x: 0; y: 1352 * win.u; width: parent.width; k: win.u; lineOnTop: true }

                // заголовок: название трека между двух линий
                Rectangle { x: 80 * win.u; y: 228 * win.u; width: 2258 * win.u; height: Math.max(1, 2 * win.u); color: Theme.ink }
                Rectangle { x: 80 * win.u; y: 288 * win.u; width: 2258 * win.u; height: Math.max(1, 2 * win.u); color: Theme.ink }
                Text {
                    x: 118 * win.u; y: 228 * win.u; height: 60 * win.u
                    width: 2150 * win.u
                    verticalAlignment: Text.AlignVCenter
                    text: Media.active ? (Media.title !== "" ? Media.title : "Unknown Track") : "No Player"
                    elide: Text.ElideRight
                    color: Theme.ink
                    font.family: Theme.font; font.pixelSize: 46 * win.u; font.letterSpacing: 3
                }

                Item {
                    x: 214 * win.u; y: 348 * win.u; width: 1206 * win.u; height: 844 * win.u
                    clip: true
                    Image {
                        anchors.fill: parent
                        source: Qt.resolvedUrl("assets/nier-art-bg.png")
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                    }

                    // обложка в рамке поверх фона (слева, где арт свободен)
                    Rectangle {
                        id: frame
                        x: 24 * win.u; y: 300 * win.u
                        width: 250 * win.u; height: width
                        color: "#F6F3E6"                         // белая рамка, как контуры персонажей
                        Rectangle {
                            anchors.fill: parent; anchors.margins: 10 * win.u
                            color: Theme.hudDarker
                            Image {
                                anchors.fill: parent; anchors.margins: 3 * win.u
                                source: Media.art
                                visible: Media.art !== "" && status === Image.Ready
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: Media.art === ""
                                text: "NO IMAGE"
                                color: Theme.hudText
                                font.family: Theme.font; font.pixelSize: 20 * win.u; font.letterSpacing: 3
                            }
                        }
                    }
                }

                Item {
                    x: 1517 * win.u; y: 348 * win.u; width: 676 * win.u; height: 844 * win.u

                    Rectangle { anchors.fill: parent; color: Theme.panel; opacity: 0.85 }
                    Rectangle {
                        id: head
                        width: parent.width; height: 58 * win.u
                        color: Theme.hudDarker
                        Text {
                            x: 30 * win.u; anchors.verticalCenter: parent.verticalCenter
                            text: "Now Playing"
                            color: Theme.hudText
                            font.family: Theme.font; font.pixelSize: 34 * win.u; font.letterSpacing: 3
                        }
                        Text {
                            anchors.right: parent.right; anchors.rightMargin: 24 * win.u
                            anchors.verticalCenter: parent.verticalCenter
                            text: !Media.active ? "--" : (Media.playing ? "PLAY" : "PAUSE")
                            color: Theme.hudText
                            font.family: Theme.font; font.pixelSize: 28 * win.u; font.letterSpacing: 2
                        }
                    }

                    Column {
                        x: 34 * win.u; y: head.height + 40 * win.u
                        width: parent.width - 68 * win.u
                        spacing: 14 * win.u

                        Text {
                            width: parent.width
                            text: Media.title !== "" ? Media.title : "-"
                            wrapMode: Text.Wrap; maximumLineCount: 3; elide: Text.ElideRight
                            color: Theme.ink
                            font.family: Theme.font; font.pixelSize: 40 * win.u; font.letterSpacing: 1
                        }
                        Text {
                            width: parent.width
                            text: Media.artist !== "" ? Media.artist : "-"
                            elide: Text.ElideRight
                            color: Theme.ink
                            font.family: Theme.font; font.pixelSize: 30 * win.u; font.letterSpacing: 1
                        }
                        Text {
                            width: parent.width
                            text: Media.album
                            visible: text !== ""
                            elide: Text.ElideRight
                            color: Theme.inkSoft
                            font.family: Theme.font; font.pixelSize: 26 * win.u
                        }
                        Rectangle { width: parent.width; height: Math.max(1, win.u); color: Theme.inkSoft }
                        Text {
                            text: Media.active ? "Player: " + Media.name : "Start a player to see it here."
                            color: Theme.inkSoft
                            font.family: Theme.font; font.pixelSize: 24 * win.u; font.letterSpacing: 1
                        }
                    }

                    // шкала из квадратиков + время
                    Item {
                        id: prog
                        x: 34 * win.u; y: parent.height - 290 * win.u
                        width: parent.width - 68 * win.u; height: 90 * win.u
                        readonly property real len: Media.player ? Media.player.length : 0
                        readonly property real pos: Media.player ? Media.player.position : 0
                        readonly property int cells: 20
                        readonly property int filled: len > 0 ? Math.min(cells, Math.floor(pos / len * cells)) : 0

                        Row {
                            spacing: (prog.width - prog.cells * 20 * win.u) / (prog.cells - 1)
                            Repeater {
                                model: prog.cells
                                Rectangle {
                                    width: 20 * win.u; height: width
                                    color: index < prog.filled ? Theme.ink : "transparent"
                                    border.width: Math.max(1, 2 * win.u); border.color: Theme.ink
                                    opacity: index < prog.filled ? 1 : 0.55
                                }
                            }
                        }
                        Text {
                            y: 40 * win.u
                            text: Media.fmt(prog.pos) + " / " + Media.fmt(prog.len)
                            color: Theme.ink
                            font.family: Theme.font; font.pixelSize: 28 * win.u; font.letterSpacing: 2
                        }
                    }

                    // кнопки: назад / играть-пауза / вперёд
                    Row {
                        x: 34 * win.u; y: parent.height - 170 * win.u
                        spacing: 24 * win.u
                        Repeater {
                            model: ["prev", "toggle", "next"]
                            Rectangle {
                                id: btn
                                required property string modelData
                                readonly property bool main: modelData === "toggle"
                                width: 150 * win.u; height: 100 * win.u
                                color: main ? Theme.ink : "transparent"
                                border.width: Math.max(1, 3 * win.u); border.color: Theme.ink
                                MediaGlyph {
                                    anchors.centerIn: parent
                                    width: 38 * win.u; height: 40 * win.u
                                    kind: btn.main ? (Media.playing ? "pause" : "play") : btn.modelData
                                    tint: btn.main ? Theme.paper : Theme.ink
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: btn.main ? Media.toggle() : (btn.modelData === "next" ? Media.next() : Media.previous())
                                }
                            }
                        }
                    }
                }

                Row {
                    x: 1760 * win.u; y: 1252 * win.u
                    spacing: 40 * win.u
                    KeyHint { key: "Space"; label: "Play" }
                    KeyHint { key: "\u2190\u2192"; label: "Track" }
                    KeyHint { key: "Esc"; label: "Back" }
                }
            }

            Item {
                anchors.fill: parent
                focus: true
                Keys.onPressed: e => {
                    if (e.key === Qt.Key_Escape) Media.open = false
                    else if (e.key === Qt.Key_Space) Media.toggle()
                    else if (e.key === Qt.Key_Right) Media.next()
                    else if (e.key === Qt.Key_Left) Media.previous()
                }
            }
        }
    }
}
