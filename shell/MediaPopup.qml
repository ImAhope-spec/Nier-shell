import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

Scope {
    id: root
    readonly property var scr: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    readonly property real u: scr ? scr.height / 1512 : 1

    GlobalShortcut {
        appid: "nier"
        name: "media"
        description: "Toggle media player"
        onPressed: Media.open = !Media.open
    }

    HyprlandFocusGrab {
        windows: [win]
        active: Media.open && Theme.mediaCloseOnOutsideClick
        onCleared: Media.open = false
    }

    PanelWindow {
        id: win
        screen: root.scr
        visible: Media.open || card.y > -card.height + 1     // остаётся видимым, пока уезжает
        anchors { top: true; right: true }
        margins { top: 518 * root.u; right: 60 * root.u }
        implicitWidth: 428 * root.u
        implicitHeight: 340 * root.u
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "nier-media"
        WlrLayershell.keyboardFocus: Media.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        Item {
            anchors.fill: parent
            clip: true

            CrtPanel {
                id: card
                width: parent.width; height: parent.height
                aberration: 1.0
                y: Media.open ? 0 : -height
                Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                // арт на весь фон (кадрируем так, чтобы головы остались сверху)
                Image {
                    anchors.fill: parent
                    source: Qt.resolvedUrl("assets/nier-art-bg.png")
                    fillMode: Image.PreserveAspectCrop
                    verticalAlignment: Image.AlignTop
                    horizontalAlignment: Image.AlignHCenter
                    smooth: true
                }

                Rectangle {
                    x: 0; y: 140 * root.u; width: parent.width; height: parent.height - y
                    color: Theme.panel; opacity: 0.95
                }
                Rectangle { x: 0; y: 140 * root.u; width: parent.width; height: Math.max(1, 2 * root.u); color: Theme.ink }

                // обложка в белой рамке
                Rectangle {
                    x: 18 * root.u; y: 98 * root.u
                    width: 124 * root.u; height: width
                    color: "#F6F3E6"
                    Rectangle {
                        anchors.fill: parent; anchors.margins: 7 * root.u
                        color: Theme.hudDarker
                        Image {
                            anchors.fill: parent; anchors.margins: 2 * root.u
                            source: Media.art
                            visible: Media.art !== "" && status === Image.Ready
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: Media.art === ""
                            text: "NO\nIMAGE"
                            horizontalAlignment: Text.AlignHCenter
                            color: Theme.hudText
                            font.family: Theme.font; font.pixelSize: 15 * root.u; font.letterSpacing: 2
                        }
                    }
                }

                Column {
                    x: 158 * root.u; y: 150 * root.u
                    width: parent.width - x - 18 * root.u
                    spacing: 4 * root.u
                    Text {
                        width: parent.width
                        text: Media.active ? (Media.title !== "" ? Media.title : "Unknown Track") : "No Player"
                        wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
                        color: Theme.ink
                        font.family: Theme.font; font.pixelSize: 21 * root.u; font.letterSpacing: 1
                    }
                    Text {
                        width: parent.width
                        text: Media.artist
                        visible: text !== ""
                        elide: Text.ElideRight
                        color: Theme.inkSoft
                        font.family: Theme.font; font.pixelSize: 16 * root.u; font.letterSpacing: 1
                    }
                }

                // шкала из квадратиков + время
                Item {
                    id: prog
                    x: 18 * root.u; y: 236 * root.u
                    width: parent.width - 36 * root.u; height: 40 * root.u
                    readonly property real len: Media.player ? Media.player.length : 0
                    readonly property real pos: Media.player ? Media.player.position : 0
                    readonly property int cells: 20
                    readonly property real cell: 14 * root.u
                    readonly property int filled: len > 0 ? Math.min(cells, Math.floor(pos / len * cells)) : 0

                    Row {
                        spacing: (prog.width - prog.cells * prog.cell) / (prog.cells - 1)
                        Repeater {
                            model: prog.cells
                            Rectangle {
                                width: prog.cell; height: width
                                color: index < prog.filled ? Theme.ink : "transparent"
                                border.width: Math.max(1, root.u); border.color: Theme.ink
                                opacity: index < prog.filled ? 1 : 0.55
                            }
                        }
                    }
                    Text {
                        y: 20 * root.u
                        text: Media.fmt(prog.pos) + " / " + Media.fmt(prog.len)
                        color: Theme.ink
                        font.family: Theme.font; font.pixelSize: 15 * root.u; font.letterSpacing: 2
                    }
                    Text {
                        anchors.right: parent.right; y: 20 * root.u
                        text: !Media.active ? "--" : (Media.playing ? "PLAY" : "PAUSE")
                        color: Theme.inkSoft
                        font.family: Theme.font; font.pixelSize: 15 * root.u; font.letterSpacing: 2
                    }
                }

                Row {
                    x: 18 * root.u; y: 284 * root.u
                    spacing: 16 * root.u
                    Repeater {
                        model: ["prev", "toggle", "next"]
                        Rectangle {
                            id: btn
                            required property string modelData
                            readonly property bool main: modelData === "toggle"
                            width: 120 * root.u; height: 40 * root.u
                            color: main ? Theme.ink : "transparent"
                            border.width: Math.max(1, 2 * root.u); border.color: Theme.ink
                            MediaGlyph {
                                anchors.centerIn: parent
                                width: 18 * root.u; height: 20 * root.u
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

            // клавиатура: Esc закрывает, Space и стрелки управляют
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
