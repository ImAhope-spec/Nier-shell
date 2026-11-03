pragma Singleton
import Quickshell
import Quickshell.Services.Mpris
import QtQuick

Singleton {
    id: m
    property bool open: false

    // активный плеер: играющий, иначе первый в списке
    readonly property var player: {
        const l = Mpris.players.values
        for (let i = 0; i < l.length; i++) if (l[i].isPlaying) return l[i]
        return l.length > 0 ? l[0] : null
    }
    readonly property bool active: player !== null
    readonly property bool playing: player ? player.isPlaying : false

    readonly property string title:  player ? (player.trackTitle  || "") : ""
    readonly property string artist: player ? (player.trackArtist || "") : ""
    readonly property string album:  player ? (player.trackAlbum  || "") : ""
    readonly property string art:    player ? (player.trackArtUrl || "") : ""
    readonly property string name:   player ? (player.identity    || "") : ""

    function fmt(s) {
        s = Math.max(0, Math.floor(s || 0))
        const mm = Math.floor(s / 60), ss = s % 60
        return (mm < 10 ? "0" : "") + mm + ":" + (ss < 10 ? "0" : "") + ss
    }
    function toggle()   { if (player && player.canTogglePlaying) player.togglePlaying() }
    function next()     { if (player && player.canGoNext) player.next() }
    function previous() { if (player && player.canGoPrevious) player.previous() }

    Timer {
        interval: 500; repeat: true
        running: m.open && m.playing
        onTriggered: if (m.player) m.player.positionChanged()
    }
}
