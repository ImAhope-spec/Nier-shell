import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import QtQuick

Scope {
    id: root
    property bool open: false
    property int tab: 0
    property int level: 0             // 0 вкладки, 1 содержимое
    property int sel: 0
    property string prompt: ""        // SSID, для которого ждём пароль
    property string pass: ""
    property string btStatus: ""
    property string soundStatus: ""
    property string powerStatus: ""
    property real lastX: -1
    property real lastY: -1

    readonly property var scr: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    readonly property real u: scr ? scr.height / 1512 : 1
    readonly property var tabs: ["Overview", "Wi-Fi", "Bluetooth", "Sound", "Power"]

    SystemClock { id: clk; precision: SystemClock.Minutes }

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var btDevices: {
        if (!adapter) return []
        const l = adapter.devices.values.slice()
        l.sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired)
                         || (a.name || a.address || "").localeCompare(b.name || b.address || ""))
        return l
    }
    readonly property int btConnected: adapter ? adapter.devices.values.filter(d => d.connected).length : 0

    function nodeName(n) { return n.nickname || n.description || n.name }
    readonly property var audioCandidates: Pipewire.nodes.values.filter(n => !n.isStream)
    PwObjectTracker { objects: root.audioCandidates }   // без этого у узлов нет данных о громкости
    readonly property var soundNodes: {
        const l = audioCandidates.filter(n => n.audio).slice()
        l.sort((a, b) => (b.isSink - a.isSink) || nodeName(a).localeCompare(nodeName(b)))
        return l
    }
    readonly property var sinkAudio: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
    readonly property real sinkVolume: sinkAudio ? sinkAudio.volume : 0
    readonly property bool sinkMuted: sinkAudio ? sinkAudio.muted : false
    function soundTag(n) {
        const def = n.isSink ? Pipewire.defaultAudioSink === n : Pipewire.defaultAudioSource === n
        return (n.isSink ? "OUT" : "IN") + (def ? "  DEFAULT" : "") + (n.audio && n.audio.muted ? "  MUTED" : "")
    }
    function soundVolume(dir) {
        const it = items[sel]
        if (it) Quickshell.execDetached(["wpctl", "set-volume", "-l", "1.0", String(it.id), dir > 0 ? "5%+" : "5%-"])
    }
    function soundMute() {
        const it = items[sel]
        if (it) Quickshell.execDetached(["wpctl", "set-mute", String(it.id), "toggle"])
    }

    readonly property var bat: UPower.displayDevice
    readonly property bool hasBat: bat && bat.isPresent
    readonly property int batPct: hasBat ? Math.round(bat.percentage * 100) : 0
    readonly property bool charging: hasBat && bat.state === UPowerDeviceState.Charging

    property real brightness: 0
    function readBrightness() { if (!bproc.running) { bproc.command = ["brightnessctl", "-m"]; bproc.running = true } }
    function setBrightness(arg) { if (!bproc.running) { bproc.command = ["brightnessctl", "-m", "-e4", "-n2", "set", arg]; bproc.running = true } }
    Process {
        id: bproc
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split("\n")[0].split(",")
                const p = parseFloat((f[3] || "").replace("%", ""))
                if (!isNaN(p)) root.brightness = p / 100
            }
        }
    }

    property string profile: ""
    property bool profileMissing: false
    readonly property var profiles: [
        { id: "power-saver", name: "Power Saver" },
        { id: "balanced", name: "Balanced" },
        { id: "performance", name: "Performance" }
    ]
    Process {
        id: pget
        command: ["sh", "-c", "powerprofilesctl get 2>/dev/null || echo __NONE__"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim()
                root.profileMissing = (t === "__NONE__" || t === "")
                root.profile = root.profileMissing ? "" : t
            }
        }
    }
    function setProfile(p) {
        Quickshell.execDetached(["powerprofilesctl", "set", p.id])
        profile = p.id
        powerStatus = "Profile: " + p.name
    }

    readonly property var overviewRows: [
        { id: "wifi", name: "Wi-Fi" },
        { id: "bt",   name: "Bluetooth" },
        { id: "vol",  name: "Volume" },
        { id: "bri",  name: "Brightness" }
    ]
    readonly property string activeSsid: {
        const n = Wifi.networks.find(x => x.active)
        return n ? n.ssid : ""
    }

    readonly property int section: tab === 1 ? 0 : (tab === 2 ? 1 : (tab === 3 ? 2 : -1))
    readonly property var items: tab === 0 ? overviewRows
        : (tab === 1 ? Wifi.networks
        : (tab === 2 ? btDevices
        : (tab === 3 ? soundNodes : profiles)))
    onItemsChanged: if (sel >= items.length) sel = Math.max(0, items.length - 1)
    onTabChanged: { sel = 0; if (open) { stopDiscovery(); refreshTab() } }

    function refreshTab() {
        if (tab === 0) { Wifi.refresh(); readBrightness() }
        else if (tab === 1) { Wifi.refresh(); Wifi.rescan() }
        else if (tab === 2 && adapter) adapter.discovering = true
        else if (tab === 4) pget.running = true
    }
    function stopDiscovery() { if (adapter && adapter.discovering) adapter.discovering = false }
    function show() {
        open = true; tab = 0; level = 0; sel = 0; prompt = ""; pass = ""
        btStatus = ""; soundStatus = ""; powerStatus = ""
        pget.running = true; refreshTab()
    }
    function hide() { open = false; stopDiscovery() }

    function sliderRow() { return (tab === 0 && items[sel] && (items[sel].id === "vol" || items[sel].id === "bri")) || tab === 3 }
    function adjust(dir) {
        const it = items[sel]
        if (!it) return
        if (tab === 3) soundVolume(dir)
        else if (it.id === "vol") Quickshell.execDetached(["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", dir > 0 ? "5%+" : "5%-"])
        else if (it.id === "bri") setBrightness(dir > 0 ? "5%+" : "5%-")
    }
    function muteToggle() {
        if (tab === 3) soundMute()
        else if (tab === 0) Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
    }

    function activate() {
        const it = items[sel]
        if (!it) return
        if (tab === 0) {
            if (it.id === "wifi") Wifi.setEnabled(!Wifi.enabled)
            else if (it.id === "bt") { if (adapter) adapter.enabled = !adapter.enabled }
            else if (it.id === "vol") muteToggle()
        } else if (tab === 1) {
            if (it.active) Wifi.disconnect(it.ssid)
            else if (it.known) Wifi.connectKnown(it.ssid)
            else if (it.security !== "") { prompt = it.ssid; pass = "" }
            else Wifi.connectOpen(it.ssid)
        } else if (tab === 2) {
            if (it.connected) { btStatus = "Disconnecting..."; it.disconnect() }
            else if (it.paired) { btStatus = "Connecting..."; it.connect() }
            else { btStatus = "Pairing... (press Enter again to connect)"; it.pair() }
        } else if (tab === 3) {
            soundStatus = "Default: " + nodeName(it)
            Quickshell.execDetached(["wpctl", "set-default", String(it.id)])
        } else if (tab === 4) {
            setProfile(it)
        }
    }
    function forgetSel() {
        const it = items[sel]
        if (!it) return
        if (tab === 1) { if (it.known) Wifi.forget(it.ssid) }
        else if (tab === 2) { btStatus = "Forgotten."; it.forget() }
    }
    function togglePower() {
        if (tab === 1) Wifi.setEnabled(!Wifi.enabled)
        else if (tab === 2 && adapter) adapter.enabled = !adapter.enabled
    }
    function rescan() {
        if (tab === 1) Wifi.rescan()
        else if (tab === 2 && adapter) { adapter.discovering = false; adapter.discovering = true }
    }
    function move(d) {
        if (level === 0) tab = Math.max(0, Math.min(tabs.length - 1, tab + d))
        else sel = Math.max(0, Math.min(items.length - 1, sel + d))
    }

    function message() {
        if (prompt !== "") return "Enter password."
        if (tab === 0) return "Overview."
        if (tab === 1) return Wifi.status !== "" ? Wifi.status : "Select network."
        if (tab === 2) return btStatus !== "" ? btStatus : "Select device."
        if (tab === 3) return soundStatus !== "" ? soundStatus : "Select device."
        return profileMissing ? "power-profiles-daemon not found." : (powerStatus !== "" ? powerStatus : "Select profile.")
    }
    function hints() {
        if (prompt !== "") return "Enter Confirm    Esc Cancel"
        if (level === 0) return "\u2191\u2193 Tab    Enter Open    Esc Close"
        if (tab === 1 || tab === 2) return "\u2191\u2193 Select  Enter OK  F Forget  R Rescan  T Power"
        if (tab === 3) return "\u2191\u2193 Select  Enter Default  \u2190\u2192 Volume  M Mute"
        if (tab === 0) return "\u2191\u2193 Select  Enter Toggle  \u2190\u2192 Adjust  M Mute"
        return "\u2191\u2193 Select  Enter Set  Esc Back"
    }

    GlobalShortcut { appid: "nier"; name: "control";  description: "Control center";  onPressed: root.open ? root.hide() : root.show() }
    GlobalShortcut { appid: "nier"; name: "settings"; description: "Settings";        onPressed: root.open ? root.hide() : root.show() }

    // клик вне панели закрывает её (и передаётся окну под курсором)
    HyprlandFocusGrab {
        windows: [win]
        active: root.open && Theme.settingsCloseOnOutsideClick
        onCleared: root.hide()
    }

    PanelWindow {
        id: win
        screen: root.scr
        visible: root.open || card.y > -card.height + 1        // остаётся видимым, пока уезжает вверх
        anchors { top: true }
        margins { top: 36 * root.u }
        implicitWidth: 1000 * root.u
        implicitHeight: 560 * root.u
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "nier-settings"
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        Item {
            anchors.fill: parent
            clip: true

            CrtPanel {
                id: card
                width: parent.width; height: parent.height
                aberration: 1.0
                y: root.open ? 0 : -height
                Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                Rectangle { anchors.fill: parent; color: Theme.panel; opacity: 0.98 }

                Rectangle {
                    id: rail
                    width: 230 * root.u; height: parent.height
                    color: Theme.hudDarker

                    Heading {
                        x: 22 * root.u; y: 16 * root.u
                        text: "SETTINGS"; size: 30 * root.u
                        color: Theme.hudText; ghostColor: Theme.hudDark
                    }
                    Repeater {
                        model: root.tabs
                        Item {
                            id: trow
                            required property string modelData
                            required property int index
                            readonly property bool active: index === root.tab
                            y: (78 + index * 58) * root.u
                            width: rail.width; height: 50 * root.u

                            Rectangle {
                                visible: trow.active
                                anchors.fill: parent; anchors.leftMargin: 12 * root.u
                                color: Theme.paper
                            }
                            Rectangle {
                                visible: trow.active && root.level === 0
                                x: 2 * root.u; anchors.verticalCenter: parent.verticalCenter
                                width: 10 * root.u; height: width; rotation: 45; color: Theme.hudText
                            }
                            Rectangle {
                                x: 30 * root.u; anchors.verticalCenter: parent.verticalCenter
                                width: 12 * root.u; height: width
                                color: trow.active ? Theme.ink : Theme.hudText
                            }
                            Text {
                                x: 56 * root.u; anchors.verticalCenter: parent.verticalCenter
                                text: trow.modelData
                                color: trow.active ? Theme.ink : Theme.hudText
                                font.family: Theme.font; font.pixelSize: 24 * root.u; font.letterSpacing: 1
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: { root.tab = trow.index; root.level = 1 }
                            }
                        }
                    }
                }

                Item {
                    id: body
                    x: 250 * root.u; y: 18 * root.u
                    width: parent.width - x - 20 * root.u
                    height: parent.height - y - 62 * root.u

                    // --- Overview: время, погода, батарея ---
                    Item {
                        visible: root.tab === 0
                        width: parent.width; height: 170 * root.u
                        Heading {
                            x: 0; y: 0
                            text: Qt.formatDateTime(clk.date, "HH:mm"); size: 92 * root.u
                        }
                        Text {
                            x: 4 * root.u; y: 112 * root.u
                            text: Qt.formatDateTime(clk.date, "dddd dd.MM.yyyy").toUpperCase()
                            color: Theme.inkSoft
                            font.family: Theme.font; font.pixelSize: 20 * root.u; font.letterSpacing: 2
                        }
                        Column {
                            x: 330 * root.u; y: 8 * root.u
                            spacing: 8 * root.u
                            Row {
                                spacing: 12 * root.u
                                Text { text: "BAT"; width: 52 * root.u; color: Theme.inkSoft
                                       font.family: Theme.font; font.pixelSize: 18 * root.u; font.letterSpacing: 2 }
                                SegBar { count: 10; filled: Math.round(root.batPct / 10); cell: 12 * root.u; visible: root.hasBat; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: root.hasBat ? root.batPct + "%" + (root.charging ? "  CHG" : "") : "AC"; color: Theme.ink
                                       font.family: Theme.font; font.pixelSize: 20 * root.u }
                            }
                            Row {
                                spacing: 12 * root.u
                                Text { text: "CPU"; width: 52 * root.u; color: Theme.inkSoft
                                       font.family: Theme.font; font.pixelSize: 18 * root.u; font.letterSpacing: 2 }
                                SegBar { count: 10; filled: Math.round(Stats.cpu * 10); cell: 12 * root.u; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: Math.round(Stats.cpu * 100) + "%"; color: Theme.ink
                                       font.family: Theme.font; font.pixelSize: 20 * root.u }
                            }
                            Row {
                                spacing: 12 * root.u
                                Text { text: "GPU"; width: 52 * root.u; color: Theme.inkSoft
                                       font.family: Theme.font; font.pixelSize: 18 * root.u; font.letterSpacing: 2 }
                                SegBar { count: 10; filled: Math.round(Math.max(0, Stats.gpu) * 10); cell: 12 * root.u; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: Stats.gpu < 0 ? "N/A" : Math.round(Stats.gpu * 100) + "%"; color: Theme.ink
                                       font.family: Theme.font; font.pixelSize: 20 * root.u }
                            }
                            Text {
                                text: (isNaN(Weather.temp) ? "--" : Math.round(Weather.temp) + "\u00b0") + "   " + Weather.text
                                    + (Location.city !== "" ? "   " + Location.city.toUpperCase() : "")
                                color: Theme.ink
                                font.family: Theme.font; font.pixelSize: 20 * root.u; font.letterSpacing: 2
                            }
                        }
                        Rectangle { y: 160 * root.u; width: parent.width; height: Math.max(1, root.u); color: Theme.ink; opacity: 0.6 }
                    }

                    Text {
                        visible: root.tab !== 0
                        text: root.tab === 1 ? (Wifi.enabled ? "Wi-Fi    Radio: ON" : "Wi-Fi    Radio: OFF")
                            : root.tab === 2 ? ("Bluetooth    " + (root.adapter ? ("Radio: " + (root.adapter.enabled ? "ON" : "OFF") + (root.adapter.discovering ? "   Scanning..." : "")) : "No adapter"))
                            : root.tab === 3 ? ("Sound    Output: " + (Pipewire.defaultAudioSink ? root.nodeName(Pipewire.defaultAudioSink) : "-"))
                            : ("Power    " + (root.hasBat ? "Battery " + root.batPct + "%" + (root.charging ? "  Charging" : "") : "AC"))
                        width: parent.width; elide: Text.ElideRight
                        color: Theme.inkSoft
                        font.family: Theme.font; font.pixelSize: 20 * root.u; font.letterSpacing: 2
                    }
                    Rectangle { visible: root.tab !== 0; y: 34 * root.u; width: parent.width; height: Math.max(1, root.u); color: Theme.ink; opacity: 0.6 }

                    Text {
                        visible: root.items.length === 0
                        y: 54 * root.u; width: parent.width; wrapMode: Text.Wrap
                        text: root.tab === 1 ? (Wifi.enabled ? "No networks found." : "Radio is off. Press T.")
                            : root.tab === 2 ? (root.adapter ? (root.adapter.enabled ? "No devices found." : "Radio is off. Press T.") : "Bluetooth is unavailable.")
                            : "No audio devices."
                        color: Theme.inkSoft
                        font.family: Theme.font; font.pixelSize: 22 * root.u; font.letterSpacing: 1
                    }

                    ListView {
                        id: list
                        y: (root.tab === 0 ? 178 : 42) * root.u
                        width: parent.width
                        height: parent.height - y
                        clip: true
                        model: root.items
                        currentIndex: root.sel
                        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                        delegate: Item {
                            id: row
                            required property var modelData
                            required property int index
                            readonly property bool active: index === root.sel && root.level === 1
                            readonly property color fg: active ? Theme.paper : Theme.ink
                            width: list.width; height: 50 * root.u

                            Rectangle {
                                anchors.fill: parent; anchors.topMargin: 3 * root.u; anchors.bottomMargin: 3 * root.u
                                color: row.active ? Theme.ink : Theme.panelHi
                                opacity: row.active ? 1.0 : 0.6
                            }

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                x: 14 * root.u; spacing: 12 * root.u
                                Rectangle {
                                    width: 12 * root.u; height: width
                                    color: row.fg; anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    width: 330 * root.u; elide: Text.ElideRight
                                    text: root.tab === 1 ? row.modelData.ssid
                                        : root.tab === 2 ? (row.modelData.name || row.modelData.address)
                                        : root.tab === 3 ? root.nodeName(row.modelData)
                                        : row.modelData.name
                                    color: row.fg
                                    font.family: Theme.font; font.pixelSize: 22 * root.u; font.letterSpacing: 1
                                }
                            }

                            // справа: состояние
                            Row {
                                anchors.right: parent.right; anchors.rightMargin: 14 * root.u
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 14 * root.u

                                Text {
                                    visible: root.tab === 0 && (row.modelData.id === "wifi" || row.modelData.id === "bt")
                                    text: root.tab !== 0 ? ""
                                        : row.modelData.id === "wifi" ? (Wifi.enabled ? (root.activeSsid !== "" ? root.activeSsid.toUpperCase() : "ON") : "OFF")
                                        : (root.adapter ? (root.adapter.enabled ? (root.btConnected > 0 ? root.btConnected + " CONNECTED" : "ON") : "OFF") : "N/A")
                                    color: row.fg
                                    font.family: Theme.font; font.pixelSize: 18 * root.u; font.letterSpacing: 2
                                }
                                Text {
                                    visible: root.tab === 0 && row.modelData.id === "vol" && root.sinkMuted
                                    text: "MUTED"; color: row.fg
                                    font.family: Theme.font; font.pixelSize: 18 * root.u; font.letterSpacing: 2
                                }
                                SegBar {
                                    visible: root.tab === 0 && (row.modelData.id === "vol" || row.modelData.id === "bri")
                                    anchors.verticalCenter: parent.verticalCenter
                                    count: 10; cell: 12 * root.u; color: row.fg
                                    filled: root.tab !== 0 ? 0 : Math.min(10, Math.round((row.modelData.id === "vol" ? (root.sinkMuted ? 0 : root.sinkVolume) : root.brightness) * 10))
                                }
                                Text {
                                    visible: root.tab === 0 && (row.modelData.id === "vol" || row.modelData.id === "bri")
                                    text: root.tab !== 0 ? "" : Math.round((row.modelData.id === "vol" ? root.sinkVolume : root.brightness) * 100) + "%"
                                    color: row.fg
                                    font.family: Theme.font; font.pixelSize: 18 * root.u
                                }

                                Text {
                                    visible: root.tab === 1
                                    text: root.tab !== 1 ? "" : (row.modelData.active ? "CONNECTED" : (row.modelData.known ? "SAVED" : ""))
                                    color: row.fg
                                    font.family: Theme.font; font.pixelSize: 17 * root.u; font.letterSpacing: 2
                                }
                                Text {
                                    visible: root.tab === 1 && row.modelData.security !== ""
                                    text: root.tab !== 1 ? "" : row.modelData.security
                                    color: row.active ? Theme.paper : Theme.inkSoft
                                    font.family: Theme.font; font.pixelSize: 14 * root.u
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                SegBar {
                                    visible: root.tab === 1
                                    anchors.verticalCenter: parent.verticalCenter
                                    count: 4; cell: 10 * root.u; color: row.fg
                                    filled: root.tab !== 1 ? 0 : Math.max(1, Math.ceil(row.modelData.signal / 25))
                                }

                                Text {
                                    visible: root.tab === 2
                                    text: root.tab !== 2 ? "" : (row.modelData.connected ? "CONNECTED" : (row.modelData.paired ? "PAIRED" : ""))
                                    color: row.fg
                                    font.family: Theme.font; font.pixelSize: 17 * root.u; font.letterSpacing: 2
                                }
                                Text {
                                    visible: root.tab === 2 && row.modelData.batteryAvailable
                                    text: root.tab !== 2 || !row.modelData.batteryAvailable ? ""
                                        : Math.round(row.modelData.battery <= 1 ? row.modelData.battery * 100 : row.modelData.battery) + "%"
                                    color: row.fg
                                    font.family: Theme.font; font.pixelSize: 17 * root.u
                                }

                                Text {
                                    visible: root.tab === 3
                                    text: root.tab !== 3 ? "" : root.soundTag(row.modelData)
                                    color: row.fg
                                    font.family: Theme.font; font.pixelSize: 15 * root.u; font.letterSpacing: 1
                                }
                                Text {
                                    visible: root.tab === 3
                                    text: root.tab !== 3 || !row.modelData.audio ? "" : Math.round(row.modelData.audio.volume * 100) + "%"
                                    color: row.fg
                                    font.family: Theme.font; font.pixelSize: 17 * root.u
                                }
                                SegBar {
                                    visible: root.tab === 3
                                    anchors.verticalCenter: parent.verticalCenter
                                    count: 10; cell: 10 * root.u; color: row.fg
                                    filled: root.tab !== 3 || !row.modelData.audio ? 0 : Math.min(10, Math.round(row.modelData.audio.volume * 10))
                                }

                                Text {
                                    visible: root.tab === 4 && root.profile === row.modelData.id
                                    text: "ACTIVE"; color: row.fg
                                    font.family: Theme.font; font.pixelSize: 17 * root.u; font.letterSpacing: 2
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onPositionChanged: m => {
                                    const p = mapToItem(null, m.x, m.y)
                                    if (Math.abs(p.x - root.lastX) > 1 || Math.abs(p.y - root.lastY) > 1) {
                                        root.lastX = p.x; root.lastY = p.y
                                        root.sel = row.index; root.level = 1
                                    }
                                }
                                onClicked: { root.sel = row.index; root.level = 1; root.activate() }
                            }
                        }
                    }
                }

                Rectangle {
                    x: 250 * root.u; y: parent.height - 50 * root.u
                    width: parent.width - x - 20 * root.u; height: 38 * root.u
                    color: Theme.panelHi
                    Rectangle { width: 6 * root.u; height: parent.height; color: Theme.ink }
                    Text {
                        x: 20 * root.u; anchors.verticalCenter: parent.verticalCenter
                        width: 230 * root.u; elide: Text.ElideRight
                        text: root.message()
                        color: Theme.ink
                        font.family: Theme.font; font.pixelSize: 18 * root.u; font.letterSpacing: 2
                    }
                    Text {
                        anchors.right: parent.right; anchors.rightMargin: 14 * root.u
                        anchors.verticalCenter: parent.verticalCenter
                        width: 440 * root.u; elide: Text.ElideLeft; horizontalAlignment: Text.AlignRight
                        text: root.hints()
                        color: Theme.inkSoft
                        font.family: Theme.font; font.pixelSize: 14 * root.u; font.letterSpacing: 1
                    }
                }

                Item {
                    visible: root.prompt !== ""
                    anchors.fill: parent
                    Rectangle { anchors.fill: parent; color: Theme.ink; opacity: 0.4 }
                    MouseArea { anchors.fill: parent }
                    Rectangle {
                        width: 520 * root.u; height: 200 * root.u
                        anchors.centerIn: parent
                        color: Theme.paper
                        border.width: Math.max(1, 2 * root.u); border.color: Theme.ink
                        Rectangle {
                            width: parent.width; height: 44 * root.u; color: Theme.ink
                            Text {
                                x: 18 * root.u; anchors.verticalCenter: parent.verticalCenter
                                text: "Password"; color: Theme.paper
                                font.family: Theme.font; font.pixelSize: 22 * root.u; font.letterSpacing: 3
                            }
                        }
                        Text {
                            x: 22 * root.u; y: 62 * root.u; width: parent.width - 44 * root.u
                            elide: Text.ElideRight
                            text: "Network: " + root.prompt
                            color: Theme.ink
                            font.family: Theme.font; font.pixelSize: 19 * root.u; font.letterSpacing: 1
                        }
                        Row {
                            x: 22 * root.u; y: 112 * root.u; spacing: 5 * root.u
                            Repeater {
                                model: Math.min(root.pass.length, 24)
                                Rectangle { width: 14 * root.u; height: width; color: Theme.ink }
                            }
                            Rectangle {
                                id: cur
                                property bool on: true
                                width: 3 * root.u; height: 14 * root.u; color: Theme.ink
                                opacity: on ? 1 : 0
                                Timer { interval: 500; running: root.prompt !== ""; repeat: true; onTriggered: cur.on = !cur.on }
                            }
                        }
                        Text {
                            anchors.right: parent.right; anchors.rightMargin: 22 * root.u
                            y: parent.height - 38 * root.u
                            text: "Enter Confirm    Esc Cancel"
                            color: Theme.inkSoft
                            font.family: Theme.font; font.pixelSize: 15 * root.u; font.letterSpacing: 1
                        }
                    }
                }

                Item {
                    anchors.fill: parent
                    focus: true
                    Keys.onPressed: e => {
                        if (root.prompt !== "") {
                            if (e.key === Qt.Key_Escape) { root.prompt = ""; root.pass = "" }
                            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                                Wifi.connectPassword(root.prompt, root.pass); root.prompt = ""; root.pass = ""
                            }
                            else if (e.key === Qt.Key_Backspace) root.pass = root.pass.slice(0, -1)
                            else if (e.text.length === 1 && e.text >= " ") root.pass += e.text
                            return
                        }
                        if (e.key === Qt.Key_Escape) { if (root.level === 1) root.level = 0; else root.hide() }
                        else if (e.key === Qt.Key_Down) root.move(1)
                        else if (e.key === Qt.Key_Up) root.move(-1)
                        else if (root.level === 1 && root.sliderRow() && (e.key === Qt.Key_Left || e.key === Qt.Key_Right)) root.adjust(e.key === Qt.Key_Right ? 1 : -1)
                        else if (e.key === Qt.Key_Left) root.level = 0
                        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Right) {
                            if (root.level === 0) root.level = 1; else root.activate()
                        }
                        else if (e.key === Qt.Key_M) root.muteToggle()
                        else if (e.key === Qt.Key_R) root.rescan()
                        else if (e.key === Qt.Key_T) root.togglePower()
                        else if (e.key === Qt.Key_F) root.forgetSel()
                    }
                }
            }
        }
    }
}
