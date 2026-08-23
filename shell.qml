import Quickshell
import QtQuick
import qs.widgets
import qs.services

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: bar

        required property ShellScreen modelData
        screen: modelData

        anchors {
            top: true
            left: true
            right: true
        }
        implicitHeight: 80

        // taille commune des lignes du bas (%, dd/MM) pour que
        // les widgets empiles partagent la meme ligne de base
        readonly property real labelSize: implicitHeight * 0.18
        color: "transparent"

        Item {
            anchors.fill: parent
            anchors.margins: 6

            Pill {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                height: 48
                Text { anchors.centerIn: parent; text: "gauche"; color: Theme.fg; font.family: Theme.font }
            }

            Pill {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                height: 48
                Workspaces { screen: bar.screen }
            }

            Pill {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 48
                Row {
                    anchors.centerIn: parent
                    spacing: 14
                    Tray {
                        anchors.verticalCenter: parent.verticalCenter
                        size: bar.implicitHeight * 0.22
                        window: bar
                    }
                    Volume {
                        anchors.bottom: parent.bottom
                        labelSize: bar.labelSize
                        size: bar.implicitHeight * 0.2
                    }
                    Battery {
                        anchors.bottom: parent.bottom
                        labelSize: bar.labelSize
                        size: bar.implicitHeight * 0.25
                    }
                    Clock {
                        anchors.bottom: parent.bottom
                        labelSize: bar.labelSize
                        size: bar.implicitHeight * 0.28
                    }
                }
            }
        }
    }
}