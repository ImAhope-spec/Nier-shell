import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

Scope {
    id: root
    property bool open: false
    property string query: ""
    property int sel: 0
    property real lastX: -1
    property real lastY: -1

    property var counts: ({})
    readonly property string usagePath: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/nier-shell/launcher-usage.json"

    function keyOf(e) { return e.id || e.name }

    readonly property var results: {
        const q = query.toLowerCase()
        const c = counts
        return DesktopEntries.applications.values
            .filter(e => !e.noDisplay && e.name.toLowerCase().includes(q))
            .sort((a, b) => {
                if (q !== "") {
                    const sa = a.name.toLowerCase().startsWith(q) ? 1 : 0
                    const sb = b.name.toLowerCase().startsWith(q) ? 1 : 0
                    if (sa !== sb) return sb - sa
                }
                const ca = c[keyOf(a)] || 0, cb = c[keyOf(b)] || 0
                if (ca !== cb) return cb - ca
                return a.name.localeCompare(b.name)
            })
    }

    function launch(e) {
        const c = Object.assign({}, counts)
        c[keyOf(e)] = (c[keyOf(e)] || 0) + 1
        counts = c
        saveUsage()
        e.execute()
        hide()
    }
    function saveUsage() {
        if (saver.running) return
        saver.command = ["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s" "$2" > "$1"', "sh", usagePath, JSON.stringify(counts)]
        saver.running = true
    }

    Process {
        command: ["sh", "-c", 'cat "$1" 2>/dev/null || echo "{}"', "sh", root.usagePath]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { try { root.counts = JSON.parse(text) } catch (e) {} }
        }
    }
    Process { id: saver }

    function show() { query = ""; sel = 0; open = true }
    function hide() { open = false }

    GlobalShortcut {
        appid: "nier"
        name: "launcher"
        description: "Toggle launcher"
        onPressed: root.open ? root.hide() : root.show()
    }

    PanelWindow {
        id: win
        visible: root.open
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "nier-launcher"
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        CrtPanel {
            anchors.fill: parent
            aberration: 1.2

            Rectangle { anchors.fill: parent; color: Theme.paper }

            // слабые диагональные линии на фоне
            Repeater {
                model: 3
                Rectangle {
                    x: parent.width * (0.50 + index * 0.06); y: -parent.height * 0.2
                    width: 1; height: parent.height * 1.6
                    rotation: -38
                    color: Theme.inkSoft; opacity: 0.25
                }
            }

            DotBorder { x: 62; y: 34; width: parent.width - 124; lineOnTop: true }
            DotBorder { x: 62; y: parent.height - 52; width: parent.width - 124; lineOnTop: false }

            Row {
                x: 70; y: 84
                spacing: 14
                Heading { text: "APPLICATIONS"; size: 56 }
                Text {
                    anchors.baseline: parent.children[0].bottom
                    text: root.query === "" ? "- All" : "- " + root.query
                    color: Theme.ink
                    font.family: Theme.font; font.pixelSize: 26; font.letterSpacing: 2
                }
            }

            Item {
                id: listArea
                x: 130; y: 230
                width: 520
                height: parent.height - 230 - 190
                clip: true

                ListView {
                    id: list
                    anchors.fill: parent
                    model: root.results
                    currentIndex: root.sel
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                    delegate: Item {
                        required property var modelData
                        required property int index
                        readonly property bool active: index === root.sel
                        width: list.width; height: 50

                        Rectangle {
                            anchors.fill: parent; anchors.topMargin: 3; anchors.bottomMargin: 3
                            color: active ? Theme.ink : Theme.panel
                            opacity: active ? 1.0 : 0.55
                        }
                        // двойные линии над/под активным
                        Rectangle { visible: active; width: parent.width; height: 1; color: Theme.ink; y: 0 }
                        Rectangle { visible: active; width: parent.width; height: 1; color: Theme.ink; y: parent.height - 1 }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            x: 14; spacing: 14
                            Rectangle {
                                width: 14; height: 14
                                color: active ? Theme.paper : Theme.ink
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: modelData.name
                                color: active ? Theme.paper : Theme.ink
                                font.family: Theme.font; font.pixelSize: 24; font.letterSpacing: 1
                                elide: Text.ElideRight
                                width: list.width - 70
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onPositionChanged: m => {
                                const p = mapToItem(null, m.x, m.y)
                                if (Math.abs(p.x - root.lastX) > 1 || Math.abs(p.y - root.lastY) > 1) {
                                    root.lastX = p.x; root.lastY = p.y
                                    root.sel = index
                                }
                            }
                            onClicked: root.launch(modelData)
                        }
                    }
                }

                // ромбик-указатель слева от выбранного
                Rectangle {
                    x: -52
                    y: (list.currentItem ? list.currentItem.y - list.contentY : 0) + 25 - 7
                    width: 14; height: 14; rotation: 45
                    color: Theme.ink
                    visible: root.results.length > 0
                }
            }

            Rectangle {
                id: bar
                x: 62; width: parent.width - 124; height: 84
                y: parent.height - 52 - 24 - height
                color: Theme.panelHi
                Rectangle { width: 8; height: parent.height; color: Theme.ink }
                Text {
                    x: 60; anchors.verticalCenter: parent.verticalCenter
                    text: root.results.length === 0 ? "No match." : "Select application."
                    color: Theme.ink
                    font.family: Theme.font; font.pixelSize: 26; font.letterSpacing: 3
                }
                Row {
                    anchors.right: parent.right; anchors.rightMargin: 60
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 36
                    KeyHint { key: "\u2191\u2193"; label: "Select" }
                    KeyHint { key: "Enter"; label: "Confirm" }
                    KeyHint { key: "Esc"; label: "Back" }
                }
            }

            Item {
                anchors.fill: parent
                focus: true
                Keys.onPressed: e => {
                    if (e.key === Qt.Key_Escape) { root.hide() }
                    else if (e.key === Qt.Key_Down || (e.modifiers & Qt.ControlModifier && (e.key === Qt.Key_N || e.key === Qt.Key_J))) {
                        root.sel = Math.min(root.sel + 1, root.results.length - 1)
                    }
                    else if (e.key === Qt.Key_Up || (e.modifiers & Qt.ControlModifier && (e.key === Qt.Key_P || e.key === Qt.Key_K))) {
                        root.sel = Math.max(root.sel - 1, 0)
                    }
                    else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                        if (root.results.length > 0) root.launch(root.results[root.sel])
                    }
                    else if (e.key === Qt.Key_Backspace) { root.query = root.query.slice(0, -1); root.sel = 0 }
                    else if (e.text.length === 1 && e.text >= " " && !(e.modifiers & Qt.ControlModifier)) {
                        root.query += e.text; root.sel = 0
                    }
                }
            }
        }
    }
}
