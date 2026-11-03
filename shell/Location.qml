pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: loc
    property real lat: NaN
    property real lon: NaN
    property string city: ""
    readonly property bool ready: !isNaN(lat) && !isNaN(lon)

    Component.onCompleted: {
        const a = parseFloat(Quickshell.env("NIER_LAT") ?? "")
        const b = parseFloat(Quickshell.env("NIER_LON") ?? "")
        if (!isNaN(a) && !isNaN(b)) { lat = a; lon = b }
        else lookup.running = true
    }

    Process {
        id: lookup
        command: ["curl", "-sf", "--max-time", "8", "https://ipwho.is/?fields=success,latitude,longitude,city"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text)
                    if (j.success !== false) { loc.lat = j.latitude; loc.lon = j.longitude; loc.city = j.city || "" }
                } catch (e) {}
            }
        }
    }
    Timer {
        interval: 300000; running: true; repeat: true
        onTriggered: if (!loc.ready && !lookup.running) lookup.running = true
    }
}
