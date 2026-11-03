pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: w
    readonly property string home: Quickshell.env("HOME") || ""
    readonly property string dir: Quickshell.env("NIER_WALLPAPERS") || (home + "/Pictures/Wallpapers")
    readonly property string statePath: (Quickshell.env("XDG_STATE_HOME") || (home + "/.local/state")) + "/nier-shell/wallpaper.txt"

    property string current: ""
    property var tree: ({ name: "", path: dir, dirs: [], files: [], count: 0, _map: ({}) })
    property var files: []          // плоский список всех файлов: [{name, path, size}]

    function apply(path) {
        current = path
        saver.command = ["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s" "$2" > "$1"', "sh", statePath, path]
        saver.running = true
    }
    function refresh() { if (!lister.running) lister.running = true }

    function byName(a, b) { return a.name.localeCompare(b.name, undefined, { numeric: true, sensitivity: "base" }) }

    function parse(text) {
        const base = dir
        const root = { name: "", path: base, dirs: [], files: [], count: 0, _map: ({}) }
        const all = []
        text.split("\n").forEach(line => {
            if (!line) return
            const tab = line.lastIndexOf("\t")
            const path = line.slice(0, tab)
            const size = parseInt(line.slice(tab + 1)) || 0
            if (path.indexOf(base + "/") !== 0) return
            const rel = path.slice(base.length + 1).split("/")
            let node = root
            for (let i = 0; i < rel.length - 1; i++) {
                let child = node._map[rel[i]]
                if (!child) {
                    child = { name: rel[i], path: node.path + "/" + rel[i], dirs: [], files: [], count: 0, _map: ({}) }
                    node._map[rel[i]] = child
                    node.dirs.push(child)
                }
                node = child
            }
            const f = { name: rel[rel.length - 1], path: path, size: size }
            node.files.push(f)
            all.push(f)
        })
        function fin(n) {
            n.dirs.sort(byName); n.files.sort(byName)
            let c = n.files.length
            n.dirs.forEach(d => { c += fin(d) })
            n.count = c
            return c
        }
        fin(root)
        files = all
        tree = root
    }

    Process {
        id: loader
        command: ["sh", "-c", 'cat "$1" 2>/dev/null', "sh", w.statePath]
        running: true
        stdout: StdioCollector { onStreamFinished: { const t = text.trim(); if (t !== "") w.current = t } }
    }
    Process { id: saver }
    Process {
        id: lister
        command: ["sh", "-c",
            'find -L "$1" -type f \\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.bmp" \\) -printf "%p\\t%s\\n" 2>/dev/null',
            "sh", w.dir]
        stdout: StdioCollector { onStreamFinished: w.parse(text) }
    }
    Component.onCompleted: refresh()
}
