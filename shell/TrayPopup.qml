import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import QtQuick

Scope {
    id: root
    property bool open: false
    property string hint: ""
    readonly property var scr: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    readonly property real u: scr ? scr.height / 1512 : 1
    readonly property int count: SystemTray.items.values.length
    readonly property int cols: 5
    readonly property int rows: Math.max(1, Math.ceil(count / cols))
    readonly property real panelH: (34 + 16 + rows * 76 + 40) * u

    property bool menuOpen: false
    property var menuItem: null
    property var menuStack: []
    property int msel: -1
    readonly property var currentMenu: menuStack.length > 0 ? menuStack[menuStack.length - 1] : null

    function cleanText(t) { return (t || "").replace(/_(.)/g, "$1") }     // убрать мнемоники "_" из DBusMenu
    function openMenu(item) {
        if (!item || !item.menu) return false
        menuItem = item; menuStack = [item.menu]; msel = -1; menuOpen = true
        return true
    }
    function closeMenu() { menuOpen = false; menuStack = []; menuItem = null; msel = -1 }
    function backMenu() {
        if (menuStack.length > 1) { menuStack = menuStack.slice(0, -1); msel = -1 }
        else closeMenu()
    }
    function activate(entry) {
        if (!entry || entry.isSeparator || !entry.enabled) return
        if (entry.hasChildren) { menuStack = menuStack.concat([entry]); msel = -1 }
        else { entry.triggered(); closeMenu() }
    }
    function moveSel(d) {
        const l = opener.children.values
        if (!l || l.length === 0) return
        let i = msel < 0 ? (d > 0 ? -1 : 0) : msel
        for (let n = 0; n < l.length; n++) {
            i = (i + d + l.length) % l.length
            if (!l[i].isSeparator && l[i].enabled) { msel = i; return }
        }
    }
    function menuKey(e) {
        if (!menuOpen) return false
        if (e.key === Qt.Key_Escape || e.key === Qt.Key_Left) backMenu()
        else if (e.key === Qt.Key_Down) moveSel(1)
        else if (e.key === Qt.Key_Up) moveSel(-1)
        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Right) {
            const l = opener.children.values
            if (msel >= 0 && msel < l.length) activate(l[msel])
        } else return false
        return true
    }
    onOpenChanged: if (!open) closeMenu()

    QsMenuOpener { id: opener; menu: root.currentMenu }

    GlobalShortcut {
        appid: "nier"
        name: "tray"
        description: "Tray"
        onPressed: root.open = !root.open
    }

    PanelWindow {
        id: win
        screen: root.scr
        visible: root.open
        anchors { top: true; left: true }
        margins { top: 215 * root.u; left: 20 * root.u }
        implicitWidth: 420 * root.u
        implicitHeight: root.panelH
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "nier-tray"
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        CrtPanel {
            anchors.fill: parent
            aberration: 1.0

            Rectangle { anchors.fill: parent; color: Theme.panel; opacity: 0.96 }
            Rectangle {
                width: parent.width; height: 34 * root.u; color: Theme.hudDarker
                Text {
                    x: 16 * root.u; anchors.verticalCenter: parent.verticalCenter
                    text: "Tray"
                    color: Theme.hudText
                    font.family: Theme.font; font.pixelSize: 20 * root.u; font.letterSpacing: 3
                }
            }

            Text {
                visible: root.count === 0
                x: 16 * root.u; y: 58 * root.u
                text: "No items."
                color: Theme.inkSoft
                font.family: Theme.font; font.pixelSize: 20 * root.u; font.letterSpacing: 1
            }

            Repeater {
                model: SystemTray.items
                Rectangle {
                    id: tile
                    required property var modelData
                    required property int index
                    x: (16 + (index % root.cols) * 78) * root.u
                    y: (50 + Math.floor(index / root.cols) * 76) * root.u
                    width: 64 * root.u; height: width
                    color: hover.containsMouse ? Theme.ink : Theme.paper
                    border.width: Math.max(1, root.u); border.color: Theme.ink

                    Image {
                        anchors.centerIn: parent
                        width: 38 * root.u; height: width
                        source: tile.modelData.icon
                        sourceSize: Qt.size(76, 76)
                        smooth: true
                        visible: status === Image.Ready
                    }
                    Text {   // запасной вариант без иконки
                        anchors.centerIn: parent
                        visible: !(tile.modelData.icon !== "")
                        text: (tile.modelData.title || tile.modelData.id || "?").charAt(0).toUpperCase()
                        color: hover.containsMouse ? Theme.paper : Theme.ink
                        font.family: Theme.font; font.pixelSize: 28 * root.u
                    }

                    MouseArea {
                        id: hover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        onEntered: root.hint = tile.modelData.tooltipTitle || tile.modelData.title || tile.modelData.id
                        onExited: root.hint = ""
                        onClicked: m => {
                            const p = tile.mapToItem(null, m.x, m.y)
                            if (m.button === Qt.LeftButton) {
                                if (tile.modelData.onlyMenu) { if (!root.openMenu(tile.modelData)) tile.modelData.display(win, p.x, p.y) }
                                else { tile.modelData.activate(); root.open = false }
                            } else if (m.button === Qt.RightButton) {
                                if (!root.openMenu(tile.modelData)) tile.modelData.display(win, p.x, p.y)
                            } else {
                                tile.modelData.secondaryActivate()
                            }
                        }
                    }
                }
            }

            // подпись под сеткой: имя приложения под курсором
            Text {
                x: 16 * root.u; y: parent.height - 30 * root.u
                width: parent.width - 32 * root.u
                elide: Text.ElideRight
                text: root.hint
                color: Theme.ink
                font.family: Theme.font; font.pixelSize: 16 * root.u; font.letterSpacing: 1
            }

            Item {
                anchors.fill: parent
                focus: true
                Keys.onPressed: e => {
                    if (root.menuKey(e)) return
                    if (e.key === Qt.Key_Escape) root.open = false
                }
            }
        }
    }

    PanelWindow {
        id: menuWin
        screen: root.scr
        visible: root.menuOpen
        anchors { top: true; left: true }
        margins { top: 215 * root.u + root.panelH + 8 * root.u; left: 20 * root.u }
        implicitWidth: 340 * root.u
        implicitHeight: 34 * root.u + Math.max(40 * root.u, Math.min(list.contentHeight, 560 * root.u)) + 6 * root.u
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "nier-tray-menu"
        WlrLayershell.keyboardFocus: root.menuOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        CrtPanel {
            anchors.fill: parent
            aberration: 1.0

            Rectangle { anchors.fill: parent; color: Theme.panel; opacity: 0.97 }

            // шапка: название приложения, "Back" внутри подменю
            Rectangle {
                id: mhead
                width: parent.width; height: 34 * root.u; color: Theme.hudDarker
                Text {
                    x: 16 * root.u; anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 100 * root.u
                    elide: Text.ElideRight
                    text: root.menuItem ? (root.menuItem.title || root.menuItem.tooltipTitle || root.menuItem.id || "Menu") : "Menu"
                    color: Theme.hudText
                    font.family: Theme.font; font.pixelSize: 18 * root.u; font.letterSpacing: 2
                }
                Text {
                    visible: root.menuStack.length > 1
                    anchors.right: parent.right; anchors.rightMargin: 14 * root.u
                    anchors.verticalCenter: parent.verticalCenter
                    text: "< Back"
                    color: Theme.hudText
                    font.family: Theme.font; font.pixelSize: 16 * root.u; font.letterSpacing: 1
                    MouseArea { anchors.fill: parent; anchors.margins: -6 * root.u; onClicked: root.backMenu() }
                }
            }

            ListView {
                id: list
                y: mhead.height + 3 * root.u
                width: parent.width; height: parent.height - y - 3 * root.u
                clip: true
                model: opener.children
                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool sep: modelData.isSeparator
                    readonly property bool active: !sep && modelData.enabled && (index === root.msel || rowMouse.containsMouse)
                    width: list.width
                    height: (sep ? 14 : 44) * root.u

                    Rectangle {   // разделитель
                        visible: row.sep
                        x: 14 * root.u; width: parent.width - 28 * root.u
                        anchors.verticalCenter: parent.verticalCenter
                        height: Math.max(1, root.u); color: Theme.inkSoft
                    }
                    Rectangle {   // фон строки
                        visible: !row.sep
                        anchors.fill: parent; anchors.topMargin: 2 * root.u; anchors.bottomMargin: 2 * root.u
                        color: row.active ? Theme.ink : Theme.panel
                        opacity: row.active ? 1.0 : 0.55
                    }
                    Row {
                        visible: !row.sep
                        anchors.verticalCenter: parent.verticalCenter
                        x: 14 * root.u; spacing: 12 * root.u
                        opacity: row.modelData.enabled ? 1.0 : 0.4
                        Rectangle {   // квадратик: закрашен, если пункт отмечен
                            width: 12 * root.u; height: width
                            anchors.verticalCenter: parent.verticalCenter
                            color: row.modelData.checkState === Qt.Checked ? (row.active ? Theme.paper : Theme.ink) : "transparent"
                            border.width: Math.max(1, root.u)
                            border.color: row.active ? Theme.paper : Theme.ink
                        }
                        Text {
                            width: list.width - 90 * root.u
                            elide: Text.ElideRight
                            text: root.cleanText(row.modelData.text)
                            color: row.active ? Theme.paper : Theme.ink
                            font.family: Theme.font; font.pixelSize: 20 * root.u; font.letterSpacing: 1
                        }
                    }
                    Text {   // стрелка у подменю
                        visible: !row.sep && row.modelData.hasChildren
                        anchors.right: parent.right; anchors.rightMargin: 16 * root.u
                        anchors.verticalCenter: parent.verticalCenter
                        text: ">"
                        color: row.active ? Theme.paper : Theme.ink
                        font.family: Theme.font; font.pixelSize: 20 * root.u
                    }
                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !row.sep
                        onEntered: root.msel = row.index
                        onClicked: root.activate(row.modelData)
                    }
                }
            }

            Item {
                anchors.fill: parent
                focus: true
                Keys.onPressed: e => root.menuKey(e)
            }
        }
    }
}
