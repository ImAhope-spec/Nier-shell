pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: w
    property real temp: NaN
    property real wind: 0
    property int code: -1
    readonly property string text: describe(code)

    function describe(c) {
        if (c < 0) return "NO DATA"
        if (c === 0) return "CLEAR"
        if (c <= 3) return "CLOUDY"
        if (c === 45 || c === 48) return "FOG"
        if (c >= 51 && c <= 57) return "DRIZZLE"
        if (c >= 61 && c <= 67) return "RAIN"
        if (c >= 71 && c <= 77) return "SNOW"
        if (c >= 80 && c <= 82) return "SHOWERS"
        if (c >= 85 && c <= 86) return "SNOW SHOWERS"
        if (c >= 95) return "THUNDERSTORM"
        return "UNKNOWN"
    }

    function fetch() { if (Location.ready) req.running = true }

    Connections {
        target: Location
        function onReadyChanged() { w.fetch() }
    }
    Timer { interval: 900000; running: true; repeat: true; onTriggered: w.fetch() }

    Process {
        id: req
        command: ["curl", "-sf", "--max-time", "10",
            "https://api.open-meteo.com/v1/forecast?latitude=" + Location.lat + "&longitude=" + Location.lon
            + "&current=temperature_2m,weather_code,wind_speed_10m&wind_speed_unit=ms"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const c = JSON.parse(text).current
                    w.temp = c.temperature_2m; w.code = c.weather_code; w.wind = c.wind_speed_10m
                } catch (e) {}
            }
        }
    }
}
