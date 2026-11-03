pragma Singleton
import QtQuick

QtObject {
    readonly property color paper:    "#E3DEC6"
    readonly property color panel:    "#D6D0B7"
    readonly property color panelHi:  "#E8E4CF"
    readonly property color ink:      "#4A4640"
    readonly property color inkSoft:  "#8C8772"
    readonly property color accent:   "#B4533A"

    readonly property color hudDark:   "#675F50"
    readonly property color hudDarker: "#4A4640"
    readonly property color hudText:   "#E8E4CF"
    readonly property color barBeige:  "#C9C3AB"
    readonly property color barGrey:   "#8A8279"

    readonly property string font: "Jost"

    readonly property int lockTimeout: 0

    // блокировать экран при сне (крышка, suspend). false = не блокировать
    readonly property bool lockOnSleep: true
    readonly property string lockWhen: "after"

    readonly property bool mediaCloseOnOutsideClick: false

    // закрывать панель буфера обмена кликом вне её
    readonly property bool clipboardCloseOnOutsideClick: true

    // закрывать панель управления (Settings) кликом вне её
    readonly property bool settingsCloseOnOutsideClick: true

    readonly property string tileUrl: "https://tile.openstreetmap.org"
    readonly property int mapZoom: 16
    readonly property color mapC0: "#675F50"
    readonly property color mapC1: "#8C866F"
    readonly property color mapC2: "#C9C3AB"
}
