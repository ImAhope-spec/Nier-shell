pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: s
    property real cpu: 0
    property real gpu: -1      // -1 = нет данных
    property var prev: null

    Process {
        id: cpuProc
        command: ["sh", "-c", "head -n1 /proc/stat"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(/\s+/).slice(1).map(Number)
                const idle = p[3] + (p[4] || 0)
                const total = p.reduce((a, b) => a + b, 0)
                if (s.prev) {
                    const dt = total - s.prev.total, di = idle - s.prev.idle
                    if (dt > 0) s.cpu = Math.max(0, Math.min(1, 1 - di / dt))
                }
                s.prev = { total: total, idle: idle }
            }
        }
    }
    Process {
        id: gpuProc
        command: ["sh", Quickshell.shellPath("scripts/gpu.sh")]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(text.trim())
                s.gpu = (isNaN(v) || v < 0) ? -1 : Math.min(1, v / 100)
            }
        }
    }
    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { cpuProc.running = true; gpuProc.running = true }
    }
}
