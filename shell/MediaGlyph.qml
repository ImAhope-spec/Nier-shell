import QtQuick

// Значки плеера, нарисованные фигурами: play | pause | next | prev
Canvas {
    id: c
    property string kind: "play"
    property color tint: Theme.ink
    onKindChanged: requestPaint()
    onTintChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        ctx.fillStyle = tint
        const w = width, h = height
        if (kind === "play") {
            ctx.beginPath(); ctx.moveTo(w * 0.2, 0); ctx.lineTo(w * 0.88, h / 2); ctx.lineTo(w * 0.2, h); ctx.closePath(); ctx.fill()
        } else if (kind === "pause") {
            ctx.fillRect(w * 0.16, 0, w * 0.24, h); ctx.fillRect(w * 0.6, 0, w * 0.24, h)
        } else if (kind === "next") {
            ctx.beginPath(); ctx.moveTo(w * 0.05, 0); ctx.lineTo(w * 0.62, h / 2); ctx.lineTo(w * 0.05, h); ctx.closePath(); ctx.fill()
            ctx.fillRect(w * 0.7, 0, w * 0.22, h)
        } else if (kind === "prev") {
            ctx.beginPath(); ctx.moveTo(w * 0.95, 0); ctx.lineTo(w * 0.38, h / 2); ctx.lineTo(w * 0.95, h); ctx.closePath(); ctx.fill()
            ctx.fillRect(w * 0.08, 0, w * 0.22, h)
        }
    }
}
