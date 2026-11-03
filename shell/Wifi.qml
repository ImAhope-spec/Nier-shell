pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Wi-Fi через NetworkManager (nmcli)
Singleton {
    id: w
    property bool enabled: true
    property var networks: []        // [{ssid, signal, security, active, known}]
    property string status: ""
    property bool busy: false

    function splitTerse(line) {
        const out = []; let cur = ""
        for (let i = 0; i < line.length; i++) {
            const c = line[i]
            if (c === "\\" && i + 1 < line.length) { cur += line[i + 1]; i++ }
            else if (c === ":") { out.push(cur); cur = "" }
            else cur += c
        }
        out.push(cur)
        return out
    }

    function parse(text) {
        const a = text.split("---KNOWN")
        enabled = a[0].trim() === "enabled"
        const b = (a[1] || "").split("---LIST")
        const known = {}
        b[0].split("\n").forEach(l => {
            if (!l) return
            const f = splitTerse(l)
            if (f[1] === "802-11-wireless") known[f[0]] = true
        })
        const by = {}
        ;(b[1] || "").split("\n").forEach(l => {
            if (!l) return
            const f = splitTerse(l)
            if (f.length < 4 || f[3] === "") return
            const n = { ssid: f[3], signal: parseInt(f[1]) || 0, security: f[2] === "--" ? "" : f[2],
                        active: f[0] === "*", known: !!known[f[3]] }
            const o = by[n.ssid]
            if (!o || n.active || (!o.active && n.signal > o.signal)) by[n.ssid] = n
        })
        const list = Object.keys(by).map(k => by[k])
        list.sort((x, y) => (y.active - x.active) || (y.known - x.known) || (y.signal - x.signal))
        networks = list
    }

    function refresh() { if (!listProc.running) listProc.running = true }
    function rescan() { status = "Scanning..."; if (!scanProc.running) scanProc.running = true }

    function run(args, okMsg, script) {
        if (act.running) return
        busy = true
        status = "Working..."
        act.okMsg = okMsg
        act.command = script
            ? ["sh", "-c", 'out=$(' + script + ' 2>&1); rc=$?; printf "%s\\n%s" "$rc" "$out"', "sh"].concat(args)
            : ["sh", "-c", 'out=$("$@" 2>&1); rc=$?; printf "%s\\n%s" "$rc" "$out"', "sh"].concat(args)
        act.running = true
    }

    function setEnabled(on)       { run(["nmcli", "radio", "wifi", on ? "on" : "off"], on ? "Wi-Fi on." : "Wi-Fi off.") }
    function connectKnown(ssid)   { run(["nmcli", "connection", "up", "id", ssid], "Connected: " + ssid) }
    function connectOpen(ssid)    { run(["nmcli", "dev", "wifi", "connect", ssid], "Connected: " + ssid) }
    function disconnect(ssid)     { run(["nmcli", "connection", "down", "id", ssid], "Disconnected.") }
    function forget(ssid)         { run(["nmcli", "connection", "delete", "id", ssid], "Forgotten: " + ssid) }
    function connectPassword(ssid, pass) {
        act.environment = ({ NIER_PASS: pass })
        run([ssid], "Connected: " + ssid, 'nmcli dev wifi connect "$1" password "$NIER_PASS"')
    }

    Process {
        id: listProc
        command: ["sh", "-c",
            "nmcli radio wifi; echo '---KNOWN'; nmcli -t -f NAME,TYPE connection show; echo '---LIST'; nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID dev wifi list 2>/dev/null"]
        stdout: StdioCollector { onStreamFinished: w.parse(text) }
    }
    Process {
        id: scanProc
        command: ["sh", "-c", "nmcli dev wifi rescan 2>/dev/null; sleep 2"]
        onExited: { if (w.status === "Scanning...") w.status = ""; w.refresh() }
    }
    Process {
        id: act
        property string okMsg: ""
        stdout: StdioCollector {
            onStreamFinished: {
                const i = text.indexOf("\n")
                const rc = parseInt(text.slice(0, i))
                const lines = text.slice(i + 1).trim().split("\n")
                w.status = rc === 0 ? act.okMsg : "Failed: " + (lines[lines.length - 1] || "error")
                w.busy = false
                act.environment = ({})
                w.refresh()
            }
        }
    }
    Timer { interval: 15000; running: true; repeat: true; onTriggered: w.refresh() }
    Component.onCompleted: refresh()
}
