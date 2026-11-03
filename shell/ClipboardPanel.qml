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
    property var entries: []            // [{ id, line, text, image }]
    property bool missing: false
    property string previewText: ""
    property string previewImage: ""
    property int previewN: 0
    property real lastX: -1
    property real lastY: -1

    readonly property var scr: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    readonly property real u: scr ? scr.height / 1512 : 1
    readonly property string runtime: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"

    readonly property var shown: entries.filter(e => query === "" || e.text.toLowerCase().indexOf(query.toLowerCase()) >= 0)
    onShownChanged: { if (sel >= shown.length) sel = Math.max(0, shown.length - 1); previewTimer.restart() }
    readonly property var cur: shown.length > 0 ? shown[Math.min(sel, shown.length - 1)] : null
    onCurChanged: previewTimer.restart()

    function show() { query = ""; sel = 0; previewText = ""; previewImage = ""; open = true; listProc.running = true }
    function hide() { open = false }
    function move(d) { if (shown.length > 0) sel = Math.max(0, Math.min(shown.length - 1, sel + d)) }

    function parse(text) {
        if (text.indexOf("__MISSING__") === 0) { missing = true; entries = []; return }
        missing = false
        const out = []
        text.split("\n").forEach(l => {
            if (!l) return
            const tab = l.indexOf("\t")
            if (tab < 0) return
            const content = l.slice(tab + 1)
            out.push({ id: l.slice(0, tab), line: l, text: content, image: /^\[\[ binary data/.test(content) })
        })
        entries = out
    }
    function paste(e) {
        if (!e) return
        Quickshell.execDetached(["sh", "-c", 'cliphist decode "$1" | wl-copy', "sh", e.id])
        hide()
    }
    function remove(e) {
        if (!e || delProc.running) return
        delProc.command = ["sh", "-c", 'printf "%s\\n" "$1" | cliphist delete', "sh", e.line]
        delProc.running = true
    }
    function wipe() { if (!delProc.running) { delProc.command = ["cliphist", "wipe"]; delProc.running = true } }

    Timer {
        id: previewTimer
        interval: 150
        onTriggered: {
            const e = root.cur
            if (!e || !root.open) { root.previewText = ""; root.previewImage = ""; return }
            if (e.image) {
                root.previewText = ""
                root.previewN = (root.previewN + 1) % 2
                imgProc.out = root.runtime + "/nier-clip-preview-" + root.previewN
                imgProc.command = ["sh", "-c", 'cliphist decode "$1" > "$2"', "sh", e.id, imgProc.out]
                imgProc.running = true
            } else {
                root.previewImage = ""
                textProc.command = ["sh", "-c", 'cliphist decode "$1" | head -c 1500', "sh", e.id]
                textProc.running = true
            }
        }
    }
    Process {
        id: listProc
        command: ["sh", "-c", "command -v cliphist >/dev/null 2>&1 || { echo __MISSING__; exit 0; }; cliphist list | head -n 300"]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }
    Process { id: textProc; stdout: StdioCollector { onStreamFinished: root.previewText = text } }
    Process {
        id: imgProc
        property string out: ""
        onExited: root.previewImage = "file://" + out
    }
    Process { id: delProc; onExited: listProc.running = true }

    GlobalShortcut {
        appid: "nier"
        name: "clipboard"
        description: "Clipboard history"
        onPressed: root.open ? root.hide() : root.show()
    }

    // клик вне панели закрывает её (и передаётся окну под курсором)
    HyprlandFocusGrab {
        windows: [win]
        active: root.open && Theme.clipboardCloseOnOutsideClick
        onCleared: root.hide()
    }

    PanelWindow {
        id: win
        screen: root.scr
        visible: root.open
        anchors { top: true; left: true }
        margins { top: 230 * root.u; left: 20 * root.u }
        implicitWidth: 470 * root.u
        implicitHeight: Math.min(820 * root.u, (root.scr ? root.scr.height : 1512) - 270 * root.u)
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "nier-clipboard"
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        CrtPanel {
            anchors.fill: parent
            aberration: 1.0

            Rectangle { anchors.fill: parent; color: Theme.panel; opacity: 0.97 }

            Rectangle {
                id: head
                width: parent.width; height: 40 * root.u; color: Theme.hudDarker
                Text {
                    x: 16 * root.u; anchors.verticalCenter: parent.verticalCenter
                    text: "Clipboard"
                    color: Theme.hudText
                    font.family: Theme.font; font.pixelSize: 22 * root.u; font.letterSpacing: 3
                }
                Text {
                    anchors.right: parent.right; anchors.rightMargin: 16 * root.u
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.shown.length + (root.query !== "" ? " / " + root.entries.length : "")
                    color: Theme.hudText; opacity: 0.8
                    font.family: Theme.font; font.pixelSize: 18 * root.u; font.letterSpacing: 1
                }
            }

            Text {
                x: 16 * root.u; y: 50 * root.u; width: parent.width - 32 * root.u
                elide: Text.ElideRight
                text: root.query !== "" ? root.query : "Type to filter"
                color: root.query !== "" ? Theme.ink : Theme.inkSoft
                font.family: Theme.font; font.pixelSize: 20 * root.u; font.letterSpacing: 1
            }
            Rectangle { x: 14 * root.u; y: 84 * root.u; width: parent.width - 28 * root.u; height: Math.max(1, root.u); color: Theme.ink; opacity: 0.6 }

            // сообщения: нет cliphist / пусто
            Text {
                visible: root.missing || (root.shown.length === 0)
                x: 16 * root.u; y: 104 * root.u; width: parent.width - 32 * root.u
                wrapMode: Text.Wrap
                text: root.missing ? "cliphist not found.\nsudo pacman -S cliphist wl-clipboard\nthen log in again."
                    : (root.query !== "" ? "No matches." : "History is empty.\nCopy something and it appears here.")
                color: Theme.inkSoft
                font.family: Theme.font; font.pixelSize: 18 * root.u; font.letterSpacing: 1
            }

            // список (листается колесом и стрелками)
            ListView {
                id: list
                x: 0; y: 92 * root.u
                width: parent.width; height: parent.height - y - 232 * root.u
                clip: true
                model: root.shown
                currentIndex: root.sel
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool active: index === root.sel
                    width: list.width; height: 46 * root.u

                    Rectangle {
                        anchors.fill: parent; anchors.leftMargin: 10 * root.u; anchors.rightMargin: 16 * root.u
                        anchors.topMargin: 2 * root.u; anchors.bottomMargin: 2 * root.u
                        color: row.active ? Theme.ink : Theme.panelHi
                        opacity: row.active ? 1.0 : 0.55
                    }
                    Rectangle {   // квадрат: закрашен у текста, контур у картинки
                        x: 22 * root.u; anchors.verticalCenter: parent.verticalCenter
                        width: 12 * root.u; height: width
                        color: row.modelData.image ? "transparent" : (row.active ? Theme.paper : Theme.ink)
                        border.width: Math.max(1, root.u); border.color: row.active ? Theme.paper : Theme.ink
                    }
                    Text {
                        x: 46 * root.u; anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 46 * root.u - 30 * root.u
                        elide: Text.ElideRight
                        text: row.modelData.image ? "Image  " + row.modelData.text.replace(/\[|\]|binary data/g, "").trim() : row.modelData.text
                        color: row.active ? Theme.paper : Theme.ink
                        font.family: Theme.font; font.pixelSize: 19 * root.u; font.letterSpacing: 1
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onPositionChanged: m => {
                            const p = mapToItem(null, m.x, m.y)
                            if (Math.abs(p.x - root.lastX) > 1 || Math.abs(p.y - root.lastY) > 1) {
                                root.lastX = p.x; root.lastY = p.y
                                root.sel = row.index
                            }
                        }
                        onClicked: root.paste(row.modelData)
                    }
                }
            }
            Rectangle {
                visible: list.contentHeight > list.height
                x: parent.width - 10 * root.u; y: list.y + list.visibleArea.yPosition * list.height
                width: 4 * root.u; height: Math.max(24 * root.u, list.visibleArea.heightRatio * list.height)
                color: Theme.ink
            }

            Rectangle { x: 14 * root.u; y: parent.height - 226 * root.u; width: parent.width - 28 * root.u; height: Math.max(1, root.u); color: Theme.ink; opacity: 0.6 }
            Item {
                x: 14 * root.u; y: parent.height - 216 * root.u
                width: parent.width - 28 * root.u; height: 170 * root.u
                clip: true
                Text {
                    visible: root.previewImage === ""
                    width: parent.width; height: parent.height
                    wrapMode: Text.Wrap; elide: Text.ElideRight
                    text: root.previewText
                    color: Theme.ink
                    font.family: Theme.font; font.pixelSize: 17 * root.u; font.letterSpacing: 1
                }
                Image {
                    visible: root.previewImage !== ""
                    anchors.fill: parent
                    source: root.previewImage
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true; cache: false
                }
            }
            Text {
                x: 16 * root.u; y: parent.height - 32 * root.u; width: parent.width - 32 * root.u
                elide: Text.ElideRight
                text: "Enter Paste    Del Delete    Shift+Del Clear    Esc Close"
                color: Theme.inkSoft
                font.family: Theme.font; font.pixelSize: 14 * root.u; font.letterSpacing: 1
            }

            Item {
                anchors.fill: parent
                focus: true
                Keys.onPressed: e => {
                    if (e.key === Qt.Key_Escape) root.hide()
                    else if (e.key === Qt.Key_Down) root.move(1)
                    else if (e.key === Qt.Key_Up) root.move(-1)
                    else if (e.key === Qt.Key_PageDown) root.move(8)
                    else if (e.key === Qt.Key_PageUp) root.move(-8)
                    else if (e.key === Qt.Key_Home) root.sel = 0
                    else if (e.key === Qt.Key_End) root.sel = Math.max(0, root.shown.length - 1)
                    else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) root.paste(root.cur)
                    else if (e.key === Qt.Key_Delete) { if (e.modifiers & Qt.ShiftModifier) root.wipe(); else root.remove(root.cur) }
                    else if (e.key === Qt.Key_Backspace) { root.query = root.query.slice(0, -1); root.sel = 0 }
                    else if (e.text.length === 1 && e.text >= " " && !(e.modifiers & Qt.ControlModifier)) { root.query += e.text; root.sel = 0 }
                }
            }
        }
    }
}
