import Quickshell
import Quickshell.Wayland
import QtQuick

// Обои на слое Background под всем остальным, с плавной сменой.
Scope {
    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            id: w
            required property var modelData
            screen: modelData
            visible: Wallpaper.current !== ""
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            mask: Region {}                       // обои не принимают ввод
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "nier-wallpaper"

            Item {
                id: stage
                anchors.fill: parent
                property bool aTop: true
                readonly property string url: Wallpaper.current !== "" ? "file://" + Wallpaper.current : ""

                function onReady(img) { aTop = (img === a) }     // новая картинка загрузилась: показываем её
                onUrlChanged: {
                    if (url === "") return
                    if (a.source == "" && b.source == "") a.source = url
                    else (aTop ? b : a).source = url
                }
                Component.onCompleted: if (url !== "") a.source = url

                Image {
                    id: a
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true; cache: false
                    opacity: stage.aTop ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 450 } }
                    onStatusChanged: if (status === Image.Ready) stage.onReady(a)
                }
                Image {
                    id: b
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true; cache: false
                    opacity: stage.aTop ? 0 : 1
                    Behavior on opacity { NumberAnimation { duration: 450 } }
                    onStatusChanged: if (status === Image.Ready) stage.onReady(b)
                }
            }
        }
    }
}
