import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Effects

Scope {
    id: root
    property bool open: false
    property string pos: "center"
    property string confirming: ""
    property real lastX: -1
    property real lastY: -1

    readonly property var actions: ({
        center: { title: "Lock",     line1: "Lock the session",   line2: "Super + Shift + L", kind: "lock",     danger: false, desc: "Lock the screen." },
        up:     { title: "Suspend",  line1: "",                   line2: "",                  kind: "suspend",  danger: false, desc: "Lock and go to sleep." },
        down:   { title: "Shutdown", line1: "",                   line2: "",                  kind: "shutdown", danger: true,  desc: "Power off the system." },
        left:   { title: "Logout",   line1: "End the session",    line2: "Back to login",     kind: "logout",   danger: true,  desc: "Close all programs and log out." },
        right:  { title: "Reboot",   line1: "Restart the system", line2: "",                  kind: "reboot",   danger: true,  desc: "Restart the system." }
    })
    readonly property var opposite: ({ up: "down", down: "up", left: "right", right: "left" })

    function show() { pos = "center"; confirming = ""; open = true }
    function hide() { open = false }
    function choose(d) { confirming = ""; pos = (opposite[d] === pos) ? "center" : d }
    function setPos(z) { if (pos !== z) { confirming = ""; pos = z } }

    function run() {
        const a = actions[pos]
        if (a.danger && confirming !== pos) { confirming = pos; return }
        hide()
        if (pos === "center") LockState.lock()
        else if (pos === "up") {
            if (Theme.lockOnSleep && Theme.lockWhen === "before") {
                LockState.lock(); Quickshell.execDetached(["sh", "-c", "sleep 0.7; systemctl suspend"])
            } else Quickshell.execDetached(["systemctl", "suspend"])   // экран заблокируется сразу после пробуждения
        }
        else if (pos === "down") Quickshell.execDetached(["systemctl", "poweroff"])
        else if (pos === "right") Quickshell.execDetached(["systemctl", "reboot"])
        else if (pos === "left") Quickshell.execDetached(["sh", "-c", "loginctl terminate-session \"$XDG_SESSION_ID\""])
    }

    GlobalShortcut {
        appid: "nier"
        name: "power"
        description: "Power menu"
        onPressed: root.open ? root.hide() : root.show()
    }

    PanelWindow {
        id: win
        visible: root.open
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "nier-power"
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        readonly property real u: Math.min(width / 1920, height / 1080)
        onVisibleChanged: if (visible) shot.captureFrame()

        CrtPanel {
            anchors.fill: parent
            aberration: 2.0

            ScreencopyView {
                id: shot
                anchors.fill: parent
                captureSource: win.screen
                live: false
                visible: false
            }
            MultiEffect {
                anchors.fill: parent
                source: shot
                blurEnabled: true; blur: 1.0; blurMax: 56
                saturation: -0.3
            }
            Rectangle { anchors.fill: parent; color: Theme.hudDark; opacity: 0.30 }
            Rectangle { anchors.fill: parent; color: Theme.paper;  opacity: 0.32 }

            Item {
                id: cv
                width: 1920 * win.u; height: 1080 * win.u
                anchors.centerIn: parent

                // пункты: позиции с макета пода
                PowerBox {
                    x: 708 * win.u; y: 490 * win.u; width: 504 * win.u; height: 100 * win.u; u: win.u
                    selected: root.pos === "center"; kind: root.actions.center.kind
                    title: root.actions.center.title; line1: root.actions.center.line1; line2: root.actions.center.line2
                    onHovered: root.choose("center")
                    onClicked: { root.pos = "center"; root.run() }
                }
                PowerBox {
                    plain: true
                    x: 708 * win.u; y: 287 * win.u; width: 504 * win.u; height: 100 * win.u; u: win.u
                    selected: root.pos === "up"; title: root.actions.up.title
                    onHovered: root.choose("up")
                    onClicked: { root.pos = "up"; root.run() }
                }
                PowerBox {
                    plain: true
                    x: 708 * win.u; y: 694 * win.u; width: 504 * win.u; height: 100 * win.u; u: win.u
                    selected: root.pos === "down"; title: root.actions.down.title
                    onHovered: root.choose("down")
                    onClicked: { root.pos = "down"; root.run() }
                }
                PowerBox {
                    x: 87 * win.u; y: 490 * win.u; width: 500 * win.u; height: 100 * win.u; u: win.u
                    selected: root.pos === "left"; kind: root.actions.left.kind
                    title: root.actions.left.title; line1: root.actions.left.line1; line2: root.actions.left.line2
                    onHovered: root.choose("left")
                    onClicked: { root.pos = "left"; root.run() }
                }
                PowerBox {
                    x: 1332 * win.u; y: 490 * win.u; width: 500 * win.u; height: 100 * win.u; u: win.u
                    selected: root.pos === "right"; kind: root.actions.right.kind
                    title: root.actions.right.title; line1: root.actions.right.line1; line2: root.actions.right.line2
                    onHovered: root.choose("right")
                    onClicked: { root.pos = "right"; root.run() }
                }

                // стрелки и точки между пунктами
                ArrowGlyph { x: 938 * win.u; y: 414 * win.u; width: 44 * win.u; height: 44 * win.u; rotation: 0 }
                Rectangle  { x: 957 * win.u; y: 467 * win.u; width: 6 * win.u; height: width; radius: width / 2; color: Theme.ink }
                ArrowGlyph { x: 938 * win.u; y: 618 * win.u; width: 44 * win.u; height: 44 * win.u; rotation: 180 }
                Rectangle  { x: 957 * win.u; y: 605 * win.u; width: 6 * win.u; height: width; radius: width / 2; color: Theme.ink }
                ArrowGlyph { x: 626 * win.u; y: 518 * win.u; width: 44 * win.u; height: 44 * win.u; rotation: 270 }
                Rectangle  { x: 672 * win.u; y: 537 * win.u; width: 6 * win.u; height: width; radius: width / 2; color: Theme.ink }
                ArrowGlyph { x: 1250 * win.u; y: 518 * win.u; width: 44 * win.u; height: 44 * win.u; rotation: 90 }
                Rectangle  { x: 1242 * win.u; y: 537 * win.u; width: 6 * win.u; height: width; radius: width / 2; color: Theme.ink }

                Text {
                    x: 0; width: parent.width; y: 870 * win.u
                    horizontalAlignment: Text.AlignHCenter
                    text: root.confirming === root.pos ? "Press Enter again to confirm." : root.actions[root.pos].desc
                    color: Theme.ink
                    font.family: Theme.font; font.pixelSize: 32 * win.u; font.letterSpacing: 3
                }

                Row {
                    anchors.right: parent.right; anchors.rightMargin: 70 * win.u
                    y: 1004 * win.u
                    spacing: 30 * win.u
                    KeyHint { key: "Enter"; label: "Confirm" }
                    KeyHint { key: "Esc"; label: "Back" }
                }
            }

            MouseArea {
                anchors.fill: parent
                z: 10
                hoverEnabled: true
                function zoneAt(mx, my) {
                    const nx = (mx - width / 2) / (width / 2)
                    const ny = (my - height / 2) / (height / 2)
                    if (Math.abs(nx) < 0.26 && Math.abs(ny) < 0.22) return "center"
                    if (Math.abs(ny) >= Math.abs(nx)) return ny < 0 ? "up" : "down"
                    return nx < 0 ? "left" : "right"
                }
                onPositionChanged: m => root.setPos(zoneAt(m.x, m.y))
                onClicked: m => { root.setPos(zoneAt(m.x, m.y)); root.run() }
            }

            Item {
                anchors.fill: parent
                focus: true
                Keys.onPressed: e => {
                    if (e.key === Qt.Key_Escape) root.hide()
                    else if (e.key === Qt.Key_Up) root.choose("up")
                    else if (e.key === Qt.Key_Down) root.choose("down")
                    else if (e.key === Qt.Key_Left) root.choose("left")
                    else if (e.key === Qt.Key_Right) root.choose("right")
                    else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) root.run()
                }
            }
        }
    }
}
