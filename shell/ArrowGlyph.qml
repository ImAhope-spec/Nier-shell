import QtQuick

Canvas {
    id: c
    property color tint: Theme.ink
    onTintChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        ctx.fillStyle = tint
        const w = width, h = height
        ctx.beginPath()
        ctx.moveTo(w * 0.5, 0)
        ctx.lineTo(w * 0.95, h * 0.85)
        ctx.lineTo(w * 0.5, h * 0.62)
        ctx.lineTo(w * 0.05, h * 0.85)
        ctx.closePath(); ctx.fill()
    }
}
