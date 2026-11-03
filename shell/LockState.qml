pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: s
    property bool wanted: false
    property bool cover: false
    property string host: ""

    function lock() { wanted = true }

    Process {
        command: ["uname", "-n"]
        running: true
        stdout: StdioCollector { onStreamFinished: s.host = text.trim() }
    }
}
