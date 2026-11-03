import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pam
import QtQuick

Scope {
    id: root
    property string pass: ""
    property string status: "Enter password."
    property bool busy: false
    readonly property string user: Quickshell.env("USER") ?? ""

    SystemClock { id: clk; precision: SystemClock.Minutes }

    function reset() { pass = ""; status = "Enter password."; busy = false }
    function submit() {
        if (busy || pass.length === 0) return
        busy = true
        status = "Verifying..."
        pam.start()
    }

    GlobalShortcut { appid: "nier"; name: "lock"; description: "Lock screen"; onPressed: LockState.lock() }

    Connections {
        target: LockState
        function onWantedChanged() {
            if (LockState.wanted && !lock.locked) { root.reset(); lock.locked = true }
        }
    }

    IdleMonitor {
        enabled: Theme.lockTimeout > 0
        timeout: Theme.lockTimeout
        onIsIdleChanged: if (isIdle && !lock.locked) LockState.lock()
    }

    readonly property bool lockBefore: Theme.lockOnSleep && Theme.lockWhen === "before"
    readonly property bool lockAfter:  Theme.lockOnSleep && Theme.lockWhen === "after"

    Process {
        id: sleepGuard
        command: ["systemd-inhibit", "--what=sleep", "--mode=delay", "--who=nier-shell",
                  "--why=Cover the screen before sleep", "cat"]
        stdinEnabled: true
        running: Theme.lockOnSleep
    }
    Timer { id: releaseGuard;  interval: 1000; onTriggered: sleepGuard.running = false }
    Timer { id: wakeLock;      interval: 50;   onTriggered: LockState.lock() }
    Timer { id: coverHide;     interval: 700;  onTriggered: LockState.cover = false }   // дать блокировке успеть показаться
    Timer { id: coverFallback; interval: 10000; onTriggered: LockState.cover = false }  // на случай, если блокировка так и не поднялась

    Process {
        command: ["dbus-monitor", "--system", "type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'"]
        running: Theme.lockOnSleep
        stdout: SplitParser {
            onRead: line => {
                if (line.indexOf("boolean true") >= 0) {          // система собирается спать
                    if (root.lockBefore) {
                        LockState.lock()
                        releaseGuard.interval = lock.locked ? 150 : 1000
                    } else if (root.lockAfter) {
                        LockState.cover = true
                        releaseGuard.interval = 700               // время, чтобы заглушка успела отрисоваться
                    }
                    releaseGuard.restart()
                } else if (line.indexOf("boolean false") >= 0) {  // проснулась
                    sleepGuard.running = true                     // снова берём блокировку на следующий сон
                    if (root.lockAfter) { wakeLock.restart(); coverFallback.restart() }
                }
            }
        }
    }

    // заглушка поверх всего (кроме настоящей блокировки), на всех мониторах
    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            required property var modelData
            screen: modelData
            visible: LockState.cover
            anchors { top: true; bottom: true; left: true; right: true }
            color: Theme.hudDarker
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "nier-lock-cover"
            Image {
                anchors.fill: parent
                source: Qt.resolvedUrl("assets/nier-art-blur.png")
                fillMode: Image.PreserveAspectCrop
                asynchronous: false
            }
            Rectangle { anchors.fill: parent; color: Theme.hudDark; opacity: 0.5 }
            Rectangle { anchors.fill: parent; color: Theme.paper;  opacity: 0.16 }
        }
    }
    Connections {
        target: lock
        function onLockedChanged() { if (lock.locked && LockState.cover) coverHide.restart() }
    }

    PamContext {
        id: pam
        configDirectory: Quickshell.shellPath("pam")
        config: "password.conf"
        onPamMessage: { if (responseRequired) respond(root.pass) }
        onCompleted: result => {
            if (result === PamResult.Success) {
                lock.locked = false
                LockState.wanted = false
                root.reset()
            } else {
                root.status = "Authentication failed."
                root.pass = ""
                root.busy = false
            }
        }
        onError: err => { root.status = "Authentication error."; root.busy = false }
    }

    WlSessionLock {
        id: lock

        WlSessionLockSurface {
            color: "black"

            Item {
                id: scr
                anchors.fill: parent
                readonly property real u: Math.min(width / 1920, height / 1080)

                CrtPanel {
                    anchors.fill: parent
                    aberration: 1.1

                    Image {
                        anchors.fill: parent
                        source: Qt.resolvedUrl("assets/nier-art-blur.png")
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                    }
                    Rectangle { anchors.fill: parent; color: Theme.hudDark; opacity: 0.5 }
                    Rectangle { anchors.fill: parent; color: Theme.paper; opacity: 0.16 }

                    // тёмные полосы сверху и снизу
                    Rectangle { x: 0; y: 0; width: parent.width; height: (parent.height - 1080 * scr.u) / 2 + 115 * scr.u; color: Theme.hudDarker; opacity: 0.92 }
                    Rectangle {
                        x: 0; width: parent.width; height: (parent.height - 1080 * scr.u) / 2 + 115 * scr.u
                        y: parent.height - height
                        color: Theme.hudDarker; opacity: 0.92
                    }

                    Item {
                        id: cv
                        width: 1920 * scr.u; height: 1080 * scr.u
                        anchors.centerIn: parent

                        Rectangle {
                            x: 325 * scr.u; y: 175 * scr.u; width: 1270 * scr.u; height: 310 * scr.u
                            color: "transparent"
                            border.width: Math.max(1, 2 * scr.u); border.color: Theme.hudText
                            opacity: 0.9
                        }
                        Text {
                            x: 325 * scr.u; width: 1270 * scr.u; y: 196 * scr.u
                            horizontalAlignment: Text.AlignHCenter
                            text: "Session Locked"
                            color: Theme.hudText
                            font.family: Theme.font; font.pixelSize: 36 * scr.u; font.letterSpacing: 4
                        }
                        Text {
                            x: 325 * scr.u; width: 1270 * scr.u; y: 246 * scr.u
                            horizontalAlignment: Text.AlignHCenter
                            text: root.user + (LockState.host !== "" ? " (" + LockState.host + ")" : "")
                            color: Theme.hudText
                            font.family: Theme.font; font.pixelSize: 20 * scr.u; font.letterSpacing: 2; font.bold: true
                        }
                        Rectangle { x: 388 * scr.u; y: 287 * scr.u; width: 1143 * scr.u; height: Math.max(1, 2 * scr.u); color: Theme.hudText; opacity: 0.9 }
                        Text {
                            x: 325 * scr.u; width: 1270 * scr.u; y: 360 * scr.u
                            horizontalAlignment: Text.AlignHCenter
                            text: Qt.formatDateTime(clk.date, "dddd dd.MM.yyyy    HH:mm")
                            color: Theme.hudText
                            font.family: Theme.font; font.pixelSize: 26 * scr.u; font.letterSpacing: 4
                        }

                        // двойная планка и ромбик слева от строки ввода (как у списка в игре)
                        Rectangle { x: 653 * scr.u; y: 576 * scr.u; width: 14 * scr.u; height: 52 * scr.u; color: Theme.hudText; opacity: 0.6 }
                        Rectangle { x: 674 * scr.u; y: 576 * scr.u; width: 4 * scr.u;  height: 52 * scr.u; color: Theme.hudText; opacity: 0.6 }
                        Rectangle {
                            x: 672 * scr.u - 7 * scr.u; y: 602 * scr.u - 7 * scr.u
                            width: 14 * scr.u; height: width; rotation: 45; color: Theme.hudText
                        }

                        Item {
                            id: field
                            x: 721 * scr.u; y: 575 * scr.u; width: 505 * scr.u; height: 54 * scr.u
                            property real shake: 0
                            transform: Translate { x: field.shake }
                            Rectangle { anchors.fill: parent; color: Theme.hudDarker; opacity: 0.95 }
                            Rectangle { width: parent.width; height: Math.max(1, scr.u); color: Theme.hudText; y: -3 * scr.u; opacity: 0.8 }
                            Rectangle { width: parent.width; height: Math.max(1, scr.u); color: Theme.hudText; y: parent.height + 2 * scr.u; opacity: 0.8 }
                            Rectangle { x: 14 * scr.u; anchors.verticalCenter: parent.verticalCenter; width: 24 * scr.u; height: width; color: Theme.hudText }
                            Text {
                                x: 54 * scr.u; anchors.verticalCenter: parent.verticalCenter
                                visible: root.pass.length === 0
                                text: "Password"
                                color: Theme.hudText; opacity: 0.6
                                font.family: Theme.font; font.pixelSize: 28 * scr.u; font.letterSpacing: 2
                            }
                            Row {
                                x: 54 * scr.u; anchors.verticalCenter: parent.verticalCenter
                                spacing: 6 * scr.u
                                Repeater {
                                    model: Math.min(root.pass.length, 22)
                                    Rectangle { width: 16 * scr.u; height: width; color: Theme.hudText }
                                }
                                Rectangle {
                                    id: cur
                                    property bool on: true
                                    visible: root.pass.length > 0
                                    width: 4 * scr.u; height: 20 * scr.u; color: Theme.hudText
                                    opacity: on ? 1 : 0
                                    Timer { interval: 500; running: cur.visible; repeat: true; onTriggered: cur.on = !cur.on }
                                }
                            }
                            SequentialAnimation {
                                id: shakeAnim
                                NumberAnimation { target: field; property: "shake"; to: -14 * scr.u; duration: 50 }
                                NumberAnimation { target: field; property: "shake"; to: 14 * scr.u; duration: 80 }
                                NumberAnimation { target: field; property: "shake"; to: -8 * scr.u; duration: 70 }
                                NumberAnimation { target: field; property: "shake"; to: 0; duration: 60 }
                            }
                            Connections {
                                target: root
                                function onStatusChanged() { if (root.status === "Authentication failed.") shakeAnim.restart() }
                            }
                        }

                        Text {
                            x: 0; width: parent.width; y: 840 * scr.u
                            horizontalAlignment: Text.AlignHCenter
                            text: root.status
                            color: Theme.hudText
                            font.family: Theme.font; font.pixelSize: 30 * scr.u; font.letterSpacing: 3
                        }

                        // подсказка в правом нижнем углу
                        Row {
                            anchors.right: parent.right; anchors.rightMargin: 70 * scr.u
                            y: 1004 * scr.u
                            spacing: 14 * scr.u
                            KeyHint { key: "Enter"; label: "Confirm" }
                        }
                    }
                }

                Item {
                    anchors.fill: parent
                    focus: true
                    Keys.onPressed: e => {
                        if (root.busy) return
                        if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) root.submit()
                        else if (e.key === Qt.Key_Escape) { root.pass = ""; root.status = "Enter password." }
                        else if (e.key === Qt.Key_Backspace) root.pass = root.pass.slice(0, -1)
                        else if (e.text.length === 1 && e.text >= " ") {
                            root.pass += e.text
                            if (root.status !== "Enter password.") root.status = "Enter password."
                        }
                    }
                }
            }
        }
    }
}
