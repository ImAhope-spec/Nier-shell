import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: map
    property real u: 1
    property int loaded: 0
    readonly property real dpr: Screen.devicePixelRatio || 1
    readonly property int zoom: Theme.mapZoom
    readonly property real ts: 320 * u
    readonly property var frac: {
        if (!Location.ready) return [0, 0]
        const n = Math.pow(2, zoom)
        const r = Location.lat * Math.PI / 180
        return [(Location.lon + 180) / 360 * n,
                (1 - Math.log(Math.tan(r) + 1 / Math.cos(r)) / Math.PI) / 2 * n]
    }
    readonly property int cx: Math.floor(frac[0])
    readonly property int cy: Math.floor(frac[1])
    readonly property string cacheDir: Quickshell.cachePath("tiles-" + Theme.tileUrl.replace(/[^a-zA-Z0-9]/g, "_"))
    clip: true

    Rectangle { anchors.fill: parent; color: Theme.hudDark }

    Item {
        id: world
        anchors.fill: parent
        layer.enabled: true
        layer.effect: ShaderEffect {
            property vector2d res: Qt.vector2d(map.width, map.height)
            property real dpr: map.dpr
            property color c0: Theme.mapC0
            property color c1: Theme.mapC1
            property color c2: Theme.mapC2
            fragmentShader: Qt.resolvedUrl("shaders/map.frag.qsb")
        }

        Repeater {
            model: Location.ready ? 9 : 0
            Item {
                id: tile
                readonly property int tx: map.cx + (index % 3 - 1)
                readonly property int ty: map.cy + (Math.floor(index / 3) - 1)
                readonly property string path: map.cacheDir + "/" + map.zoom + "_" + tx + "_" + ty + ".png"
                readonly property string url: Theme.tileUrl + "/" + map.zoom + "/" + tx + "/" + ty + ".png"
                property bool have: false
                x: map.width / 2 + (tx - map.frac[0]) * map.ts
                y: map.height / 2 + (ty - map.frac[1]) * map.ts
                width: map.ts; height: map.ts

                Process {
                    id: dl
                    command: ["sh", "-c",
                        `P="${tile.path}"; mkdir -p "${map.cacheDir}";
                        if [ ! -s "$P" ]; then
                          curl -sS --max-time 15 -A "nier-shell/0.1 (personal desktop widget)" -o "$P.tmp" -w "%{http_code} ${tile.url}\\n" "${tile.url}" >> /tmp/nier-tiles.log 2>&1;
                          if [ "$(head -c 4 "$P.tmp" 2>/dev/null | od -An -tx1 | tr -d ' \\n')" = "89504e47" ]; then mv "$P.tmp" "$P"; else rm -f "$P.tmp"; fi
                        fi
                        [ -s "$P" ]`]
                    running: true
                    onExited: code => {
                        if (code === 0 && !tile.have) { tile.have = true; map.loaded++ }
                    }
                }
                Timer {   // повторяем неудавшиеся
                    interval: 30000; repeat: true; running: !tile.have
                    onTriggered: if (!dl.running) dl.running = true
                }
                Image {
                    anchors.fill: parent
                    source: tile.have ? "file://" + tile.path : ""
                    cache: false
                }
            }
        }
    }

    // стрелка игрока в центре
    Canvas {
        width: 34 * map.u; height: 34 * map.u
        x: map.width / 2 - width / 2; y: map.height / 2 - height / 2
        onPaint: {
            const c = getContext("2d")
            c.reset()
            c.beginPath()
            c.moveTo(width * 0.15, height * 0.5)
            c.lineTo(width * 0.85, height * 0.12)
            c.lineTo(width * 0.62, height * 0.5)
            c.lineTo(width * 0.85, height * 0.88)
            c.closePath()
            c.fillStyle = Theme.paper
            c.fill()
            c.lineWidth = 2
            c.strokeStyle = Theme.hudDarker
            c.stroke()
        }
        rotation: -30
    }

    // пока нет ни одного тайла
    Column {
        visible: map.loaded === 0
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 44 * map.u
        spacing: 6 * map.u
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Location.ready ? "NO SIGNAL" : "LOCATING"
            color: Theme.hudText
            font.family: Theme.font; font.pixelSize: 20 * map.u; font.letterSpacing: 4
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: Location.ready
            text: "MAP DATA UNAVAILABLE"
            color: Theme.hudText; opacity: 0.6
            font.family: Theme.font; font.pixelSize: 12 * map.u; font.letterSpacing: 2
        }
    }

    Rectangle { anchors.fill: parent; color: "transparent"; border.width: 2; border.color: Theme.hudText; opacity: 0.35 }
}
