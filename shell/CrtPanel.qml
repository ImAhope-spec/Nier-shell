import QtQuick

Item {
    id: root
    default property alias content: holder.data
    property real aberration: 1.0
    readonly property real dpr: Screen.devicePixelRatio || 1

    Item {
        id: holder
        anchors.fill: parent
        layer.enabled: true
        layer.smooth: true
        layer.effect: ShaderEffect {
            property vector2d res: Qt.vector2d(root.width, root.height)
            property real aberr: root.aberration
            property real dpr: root.dpr
            fragmentShader: Qt.resolvedUrl("shaders/crt.frag.qsb")
        }
    }
}
