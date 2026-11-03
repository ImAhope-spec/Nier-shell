import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

Scope {
    id: root
    property bool open: false
    property int sel: 0
    property var expanded: ({})
    property string status: ""
    property bool revealed: false
    property real lastX: -1
    property real lastY: -1

    function buildRows(tree, exp) {
        const out = []
        function walk(node, depth, guides) {
            const items = node.dirs.map(d => ({ kind: "dir", node: d })).concat(node.files.map(f => ({ kind: "file", file: f })))
            items.forEach((it, i) => {
                const last = i === items.length - 1
                if (it.kind === "dir") {
                    const open = !!exp[it.node.path]
                    out.push({ kind: "dir", name: it.node.name, path: it.node.path, depth: depth, last: last, guides: guides, open: open, count: it.node.count, node: it.node })
                    if (open) walk(it.node, depth + 1, depth >= 1 ? guides.concat([!last]) : guides)
                } else {
                    out.push({ kind: "file", name: it.file.name, path: it.file.path, depth: depth, last: last, guides: guides, file: it.file })
                }
            })
        }
        walk(tree, 0, [])
        return out
    }
    readonly property var rows: buildRows(Wallpaper.tree, expanded)
    readonly property var cur: rows.length > 0 ? rows[Math.min(sel, rows.length - 1)] : null

    function firstFile(node) {
        if (node.files.length > 0) return node.files[0]
        for (let i = 0; i < node.dirs.length; i++) { const f = firstFile(node.dirs[i]); if (f) return f }
        return null
    }
    readonly property var previewFile: cur ? (cur.kind === "file" ? cur.file : firstFile(cur.node)) : null

    function fmtSize(b) { return b >= 1048576 ? (b / 1048576).toFixed(1) + " MB" : Math.max(1, Math.round(b / 1024)) + " KB" }
    function baseName(n) { return n.replace(/\.[^.]+$/, "") }
    function relDir(p) {
        const rel = p.slice(Wallpaper.dir.length + 1)
        const i = rel.lastIndexOf("/")
        return i < 0 ? "/" : rel.slice(0, i)
    }

    function toggle(path) {
        const e = Object.assign({}, expanded)
        if (e[path]) delete e[path]; else e[path] = true
        expanded = e
    }
    function move(d) { if (rows.length > 0) sel = Math.max(0, Math.min(rows.length - 1, sel + d)) }
    function reveal() {
        const c = Wallpaper.current, base = Wallpaper.dir
        if (!c || c.indexOf(base + "/") !== 0) return
        const parts = c.slice(base.length + 1).split("/")
        const e = Object.assign({}, expanded)
        let p = base
        for (let i = 0; i < parts.length - 1; i++) { p += "/" + parts[i]; e[p] = true }
        expanded = e
        for (let i = 0; i < rows.length; i++) if (rows[i].path === c) { sel = i; break }
    }
    function applyFile(f) {
        if (!f) return
        Wallpaper.apply(f.path)
        status = "Applied: " + baseName(f.name)
    }
    function activate() {
        const r = cur
        if (!r) return
        if (r.kind === "dir") toggle(r.path)
        else applyFile(r.file)
    }
    function randomWallpaper() {
        const l = Wallpaper.files
        if (l.length === 0) return
        applyFile(l[Math.floor(Math.random() * l.length)])
    }
    function show() { open = true; status = ""; revealed = false; sel = 0; Wallpaper.refresh(); if (Wallpaper.files.length > 0) { reveal(); revealed = true } }
    function hide() { open = false }

    Connections {
        target: Wallpaper
        function onTreeChanged() { if (root.open && !root.revealed) { root.reveal(); root.revealed = true } }
    }

    GlobalShortcut {
        appid: "nier"
        name: "wallpaper"
        description: "Wallpaper manager"
        onPressed: root.open ? root.hide() : root.show()
    }

    PanelWindow {
        id: win
        visible: root.open
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "nier-wallpapers"
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        readonly property real u: Math.min(width / 1920, height / 1080)

        CrtPanel {
            anchors.fill: parent
            aberration: 1.2

            Rectangle { anchors.fill: parent; color: Theme.paper }

            Item {
                id: cv
                width: 1920 * win.u; height: 1080 * win.u
                anchors.centerIn: parent

                // слабые диагональные линии фона
                Repeater {
                    model: 3
                    Rectangle {
                        x: cv.width * (0.50 + index * 0.06); y: -cv.height * 0.2
                        width: 1; height: cv.height * 1.6; rotation: -38
                        color: Theme.inkSoft; opacity: 0.25
                    }
                }

                DotBorder { x: 62 * win.u; y: 36 * win.u; width: cv.width - 124 * win.u; k: win.u; lineOnTop: true }
                DotBorder { x: 62 * win.u; y: 1008 * win.u; width: cv.width - 124 * win.u; k: win.u; lineOnTop: false }

                Heading { x: 68 * win.u; y: 84 * win.u; text: "WALLPAPERS"; size: 64 * win.u }
                Text {
                    anchors.right: parent.right; anchors.rightMargin: 68 * win.u
                    y: 92 * win.u
                    text: "Total Wallpapers: " + Wallpaper.files.length
                    color: Theme.ink
                    font.family: Theme.font; font.pixelSize: 30 * win.u; font.letterSpacing: 2
                }

                Rectangle { x: 62 * win.u; y: 230 * win.u; width: 14 * win.u; height: 573 * win.u; color: Theme.inkSoft; opacity: 0.45 }
                Rectangle { x: 80 * win.u; y: 230 * win.u; width: 4 * win.u; height: 573 * win.u; color: Theme.inkSoft; opacity: 0.6 }

                Item {
                    x: 128 * win.u; y: 230 * win.u; width: 813 * win.u; height: 573 * win.u
                    Rectangle { anchors.fill: parent; color: Theme.panelHi; opacity: 0.8 }
                    Rectangle { x: 12 * win.u; y: 5 * win.u; width: parent.width - 24 * win.u; height: Math.max(1, win.u); color: Theme.ink; opacity: 0.6 }
                    Rectangle { x: 12 * win.u; y: parent.height - 6 * win.u; width: parent.width - 24 * win.u; height: Math.max(1, win.u); color: Theme.ink; opacity: 0.6 }

                    Text {
                        visible: root.rows.length === 0
                        x: 24 * win.u; y: 60 * win.u; width: parent.width - 48 * win.u
                        wrapMode: Text.Wrap
                        text: "No wallpapers found.\nPut images (jpg, png, webp) into\n" + Wallpaper.dir + "\nSubfolders become folders here."
                        color: Theme.inkSoft
                        font.family: Theme.font; font.pixelSize: 26 * win.u; font.letterSpacing: 1
                    }

                    ListView {
                        id: list
                        x: 0; y: 10 * win.u; width: 773 * win.u; height: 553 * win.u
                        clip: true
                        model: root.rows
                        currentIndex: root.sel
                        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                        delegate: Item {
                            id: row
                            required property var modelData
                            required property int index
                            readonly property bool active: index === root.sel
                            readonly property color ink: active ? Theme.paper : Theme.ink
                            readonly property real textX: (45 + 38 * modelData.depth) * win.u
                            width: list.width; height: 60 * win.u

                            Rectangle {   // выбранная строка
                                visible: row.active
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width; height: 48 * win.u
                                color: Theme.ink
                            }

                            // вертикальные линии предков и соединитель текущего уровня
                            Repeater {
                                model: row.modelData.depth >= 1 ? row.modelData.guides : []
                                Rectangle {
                                    required property bool modelData
                                    required property int index
                                    visible: modelData
                                    x: (62 + 38 * index) * win.u; width: 3 * win.u
                                    y: 0; height: row.height
                                    color: row.ink
                                }
                            }
                            Item {
                                visible: row.modelData.depth >= 1
                                x: (62 + 38 * (row.modelData.depth - 1)) * win.u
                                width: 40 * win.u; height: row.height
                                Rectangle { width: 3 * win.u; y: 0; height: row.modelData.last ? row.height / 2 : row.height; color: row.ink }
                                Rectangle { x: 0; y: row.height / 2 - 1.5 * win.u; width: 18 * win.u; height: 3 * win.u; color: row.ink }
                            }

                            // значок: [+]/[-] у папки, квадрат у файла в корне
                            Rectangle {
                                visible: row.modelData.kind === "dir"
                                x: (12 + 38 * row.modelData.depth) * win.u; anchors.verticalCenter: parent.verticalCenter
                                width: 22 * win.u; height: width
                                color: "transparent"
                                border.width: Math.max(1, 2 * win.u); border.color: row.ink
                                Rectangle { anchors.centerIn: parent; width: 12 * win.u; height: 3 * win.u; color: row.ink }
                                Rectangle { visible: !row.modelData.open; anchors.centerIn: parent; width: 3 * win.u; height: 12 * win.u; color: row.ink }
                            }
                            Rectangle {
                                visible: row.modelData.kind === "file" && row.modelData.depth === 0
                                x: 16 * win.u; anchors.verticalCenter: parent.verticalCenter
                                width: 14 * win.u; height: width; color: row.ink
                            }

                            Text {
                                x: row.textX; anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - row.textX - 150 * win.u
                                elide: Text.ElideRight
                                text: row.modelData.kind === "dir" ? row.modelData.name : root.baseName(row.modelData.name)
                                color: row.ink
                                font.family: Theme.font; font.pixelSize: 28 * win.u; font.letterSpacing: 1
                            }
                            Text {   // число файлов в папке / метка текущих обоев
                                anchors.right: parent.right; anchors.rightMargin: 36 * win.u
                                anchors.verticalCenter: parent.verticalCenter
                                text: row.modelData.kind === "dir" ? row.modelData.count
                                    : (row.modelData.path === Wallpaper.current ? "SET" : "")
                                color: row.active ? Theme.paper : Theme.inkSoft
                                font.family: Theme.font; font.pixelSize: 22 * win.u; font.letterSpacing: 2
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
                                onClicked: { root.sel = row.index; if (row.modelData.kind === "dir") root.toggle(row.modelData.path) }
                                onDoubleClicked: if (row.modelData.kind === "file") root.applyFile(row.modelData.file)
                            }
                        }
                    }

                    Rectangle {
                        visible: list.contentHeight > list.height
                        x: parent.width - 22 * win.u; y: 18 * win.u + list.visibleArea.yPosition * (parent.height - 36 * win.u)
                        width: 4 * win.u; height: Math.max(24 * win.u, list.visibleArea.heightRatio * (parent.height - 36 * win.u))
                        color: Theme.ink
                    }
                    Rectangle { x: parent.width - 21 * win.u; y: 12 * win.u; width: 5 * win.u; height: width; color: Theme.ink }
                    Rectangle { x: parent.width - 21 * win.u; y: parent.height - 18 * win.u; width: 5 * win.u; height: width; color: Theme.ink }
                }

                Rectangle {
                    visible: root.rows.length > 0 && list.currentItem !== null
                    x: 88 * win.u - 7 * win.u
                    y: 240 * win.u + (list.currentItem ? list.currentItem.y - list.contentY : 0) + 30 * win.u - 7 * win.u
                    width: 14 * win.u; height: width; rotation: 45; color: Theme.ink
                }

                Item {
                    x: 990 * win.u; y: 229 * win.u; width: 868 * win.u; height: 574 * win.u
                    Rectangle { anchors.fill: parent; color: Theme.panelHi; opacity: 0.8 }
                    Rectangle {
                        width: parent.width; height: 48 * win.u; color: Theme.hudDarker
                        Rectangle { x: 14 * win.u; anchors.verticalCenter: parent.verticalCenter; width: 24 * win.u; height: width; color: Theme.hudText }
                        Text {
                            x: 48 * win.u; anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 64 * win.u; elide: Text.ElideRight
                            text: root.cur ? (root.cur.kind === "dir" ? root.cur.name : root.baseName(root.cur.name)) : "-"
                            color: Theme.hudText
                            font.family: Theme.font; font.pixelSize: 28 * win.u; font.letterSpacing: 2
                        }
                    }

                    Rectangle { x: 24 * win.u; y: 64 * win.u; width: 574 * win.u; height: 323 * win.u; color: Theme.barBeige; opacity: 0.6 }
                    Image {
                        id: preview
                        x: 24 * win.u; y: 64 * win.u; width: 574 * win.u; height: 323 * win.u
                        source: root.previewFile ? "file://" + root.previewFile.path : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true; cache: false
                        smooth: true
                        clip: true
                    }

                    // сведения справа от превью
                    Column {
                        x: 614 * win.u; y: 58 * win.u; width: 232 * win.u
                        spacing: 4 * win.u
                        Text {
                            text: root.cur && root.cur.kind === "dir" ? "Folder" : "Image"
                            color: Theme.ink
                            font.family: Theme.font; font.pixelSize: 26 * win.u; font.letterSpacing: 2
                        }
                        Rectangle { width: parent.width; height: Math.max(1, win.u); color: Theme.inkSoft }
                        Repeater {
                            model: {
                                const r = root.cur
                                if (!r) return []
                                if (r.kind === "dir") return [["Images", String(r.count)], ["Folders", String(r.node.dirs.length)]]
                                return [["Size", root.fmtSize(r.file.size)],
                                        ["Res", preview.status === Image.Ready ? preview.implicitWidth + "x" + preview.implicitHeight : "-"],
                                        ["In use", r.path === Wallpaper.current ? "Yes" : "No"]]
                            }
                            Item {
                                required property var modelData
                                width: 232 * win.u; height: 36 * win.u
                                Text { text: modelData[0] + ":"; color: Theme.ink; anchors.verticalCenter: parent.verticalCenter
                                       font.family: Theme.font; font.pixelSize: 24 * win.u; font.letterSpacing: 1 }
                                Text { text: modelData[1]; color: Theme.ink; anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right
                                       font.family: Theme.font; font.pixelSize: 24 * win.u; font.letterSpacing: 1 }
                            }
                        }
                    }

                    Rectangle { x: 24 * win.u; y: 403 * win.u; width: parent.width - 48 * win.u; height: Math.max(1, 2 * win.u); color: Theme.inkSoft }
                    Text {
                        x: 24 * win.u; y: 414 * win.u; width: parent.width - 48 * win.u
                        wrapMode: Text.Wrap; maximumLineCount: 3; elide: Text.ElideRight
                        text: !root.cur ? "" : (root.cur.kind === "dir"
                            ? "Press Enter to " + (root.cur.open ? "close" : "open") + " the folder."
                            : "Folder: " + root.relDir(root.cur.path) + "\\nPress Enter to set as wallpaper.")
                        color: Theme.ink
                        font.family: Theme.font; font.pixelSize: 26 * win.u; font.letterSpacing: 1
                    }
                    Rectangle { x: 24 * win.u; y: 559 * win.u; width: parent.width - 48 * win.u; height: Math.max(1, 2 * win.u); color: Theme.inkSoft }
                }

                Rectangle {
                    x: 62 * win.u; y: 911 * win.u; width: cv.width - 124 * win.u; height: 80 * win.u
                    color: Theme.panelHi
                    Rectangle { width: 8 * win.u; height: parent.height; color: Theme.ink }
                    Text {
                        x: 58 * win.u; anchors.verticalCenter: parent.verticalCenter
                        width: 760 * win.u; elide: Text.ElideRight
                        text: root.status !== "" ? root.status : "Choose a wallpaper."
                        color: Theme.ink
                        font.family: Theme.font; font.pixelSize: 26 * win.u; font.letterSpacing: 3
                    }
                    Row {
                        anchors.right: parent.right; anchors.rightMargin: 40 * win.u
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 26 * win.u
                        KeyHint { key: "\u2191\u2193"; label: "Select" }
                        KeyHint { key: "Enter"; label: root.cur && root.cur.kind === "dir" ? (root.cur.open ? "Close" : "Open") : "Confirm" }
                        KeyHint { key: "R"; label: "Random" }
                        KeyHint { key: "Esc"; label: "Back" }
                    }
                }
            }

            Item {
                anchors.fill: parent
                focus: true
                Keys.onPressed: e => {
                    if (e.key === Qt.Key_Escape) root.hide()
                    else if (e.key === Qt.Key_Down || e.key === Qt.Key_S) root.move(1)
                    else if (e.key === Qt.Key_Up || e.key === Qt.Key_W) root.move(-1)
                    else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) root.activate()
                    else if (e.key === Qt.Key_Right) { if (root.cur && root.cur.kind === "dir" && !root.cur.open) root.toggle(root.cur.path) }
                    else if (e.key === Qt.Key_Left) {
                        if (root.cur && root.cur.kind === "dir" && root.cur.open) root.toggle(root.cur.path)
                        else if (root.cur && root.cur.depth >= 1) {
                            // перейти к родительской папке
                            const parent = root.cur.path.slice(0, root.cur.path.lastIndexOf("/"))
                            for (let i = root.sel - 1; i >= 0; i--) if (root.rows[i].path === parent) { root.sel = i; break }
                        }
                    }
                    else if (e.key === Qt.Key_R) root.randomWallpaper()
                }
            }
        }
    }
}
