import Quickshell
import Quickshell.Services.Notifications
import QtQuick

Scope {
    id: root

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        onNotification: n => { n.tracked = true }
    }

    Variants {
        model: Quickshell.screens
        delegate: HudWindow {
            id: w
            required property var modelData
            screen: modelData
            u: modelData.height / 1512
            onTop: true
            mx: 21 * u
            my: 432 * u
            implicitWidth: 320 * u
            implicitHeight: Math.max(1, col.implicitHeight)
            visible: server.trackedNotifications.values.length > 0

            Column {
                id: col
                width: parent.width
                spacing: 12 * w.u

                Repeater {
                    model: server.trackedNotifications
                    delegate: Item {
                        id: card
                        required property var modelData
                        width: col.width
                        height: head.height + body.height

                        Timer { interval: 7000; running: true; onTriggered: card.modelData.expire() }

                        Rectangle {
                            id: head
                            width: parent.width; height: 28 * w.u
                            color: Theme.hudDarker
                            Text {
                                x: 14 * w.u; anchors.verticalCenter: parent.verticalCenter
                                text: (card.modelData.appName || "NOTICE").toUpperCase()
                                color: Theme.hudText
                                font.family: Theme.font; font.pixelSize: 15 * w.u; font.letterSpacing: 3
                            }
                        }
                        Rectangle {
                            id: body
                            y: head.height
                            width: parent.width
                            height: Math.max(64 * w.u, txt.implicitHeight + 28 * w.u)
                            color: Theme.hudDark

                            Rectangle {   // "клавиша"
                                id: cap
                                x: 14 * w.u; anchors.verticalCenter: parent.verticalCenter
                                width: 34 * w.u; height: 34 * w.u; radius: 3
                                color: Theme.hudText
                                Text {
                                    anchors.centerIn: parent; text: "!"
                                    color: Theme.hudDarker
                                    font.family: Theme.font; font.pixelSize: 22 * w.u; font.bold: true
                                }
                            }
                            Column {
                                id: txt
                                x: cap.x + cap.width + 14 * w.u
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - x - 14 * w.u
                                spacing: 2 * w.u
                                Text {
                                    width: parent.width
                                    text: card.modelData.summary
                                    color: Theme.hudText
                                    wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
                                    font.family: Theme.font; font.pixelSize: 20 * w.u; font.letterSpacing: 1
                                }
                                Text {
                                    width: parent.width
                                    visible: text !== ""
                                    text: card.modelData.body
                                    color: Theme.hudText; opacity: 0.75
                                    wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
                                    font.family: Theme.font; font.pixelSize: 15 * w.u
                                }
                            }
                        }
                        MouseArea { anchors.fill: parent; onClicked: card.modelData.expire() }
                    }
                }
            }
        }
    }
}
