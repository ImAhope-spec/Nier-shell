import QtQuick

// Значки меню питания: lock | suspend | shutdown | reboot | logout
Canvas {
    id: c
    property string kind: "lock"
    property color tint: Theme.ink
    onKindChanged: requestPaint()
    onTintChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const w = width, h = height, s = Math.min(w, h)
        const cx = w / 2, cy = h / 2
        ctx.strokeStyle = tint; ctx.fillStyle = tint
        ctx.lineWidth = Math.max(2, s * 0.09); ctx.lineCap = "butt"; ctx.lineJoin = "miter"
        if (kind === "lock") {
            ctx.fillRect(cx - s * 0.30, cy - s * 0.02, s * 0.60, s * 0.42)
            ctx.beginPath(); ctx.arc(cx, cy - s * 0.02, s * 0.20, Math.PI, 2 * Math.PI); ctx.stroke()
        } else if (kind === "suspend") {
            ctx.beginPath(); ctx.arc(cx, cy, s * 0.34, 0, 2 * Math.PI); ctx.fill()
            ctx.globalCompositeOperation = "destination-out"
            ctx.beginPath(); ctx.arc(cx + s * 0.18, cy - s * 0.12, s * 0.30, 0, 2 * Math.PI); ctx.fill()
        } else if (kind === "shutdown") {
            ctx.beginPath(); ctx.arc(cx, cy + s * 0.03, s * 0.30, -Math.PI * 0.30, Math.PI * 1.30, false); ctx.stroke()
            ctx.beginPath(); ctx.moveTo(cx, cy - s * 0.38); ctx.lineTo(cx, cy - s * 0.04); ctx.stroke()
        } else if (kind === "reboot") {
            ctx.beginPath(); ctx.arc(cx, cy, s * 0.30, -Math.PI * 0.15, Math.PI * 1.45, false); ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(cx + s * 0.30, cy - s * 0.30); ctx.lineTo(cx + s * 0.30, cy + s * 0.02); ctx.lineTo(cx - s * 0.02, cy - s * 0.02)
            ctx.closePath(); ctx.fill()
        } else if (kind === "logout") {
            ctx.beginPath()
            ctx.moveTo(cx - s * 0.04, cy - s * 0.34); ctx.lineTo(cx - s * 0.34, cy - s * 0.34)
            ctx.lineTo(cx - s * 0.34, cy + s * 0.34); ctx.lineTo(cx - s * 0.04, cy + s * 0.34); ctx.stroke()
            ctx.beginPath(); ctx.moveTo(cx - s * 0.10, cy); ctx.lineTo(cx + s * 0.28, cy); ctx.stroke()
            ctx.beginPath(); ctx.moveTo(cx + s * 0.40, cy); ctx.lineTo(cx + s * 0.16, cy - s * 0.18); ctx.lineTo(cx + s * 0.16, cy + s * 0.18)
            ctx.closePath(); ctx.fill()
        }
    }
}
