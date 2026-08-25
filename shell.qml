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

        readonly property bool vertical: Config.vertical

        // Une barre horizontale s'etire sur toute la largeur (left + right)
        // et impose sa hauteur ; une verticale fait l'inverse. La dimension
        // libre reste a 0 : c'est l'ancrage qui l'etire.
        anchors {
            top: true
            left: true
            right: !bar.vertical
            bottom: bar.vertical
        }
        implicitHeight: bar.vertical ? 0 : Config.barSize
        implicitWidth: bar.vertical ? Config.barSize : 0

        // epaisseur des bulles, dans la dimension contrainte
        readonly property real pillThickness: Config.barSize * (bar.vertical ? 0.8 : 0.6)
        // taille commune des lignes du bas (%, dd/MM) pour que
        // les widgets empiles partagent la meme ligne de base
        readonly property real labelSize: Config.barSize * (bar.vertical ? 0.22 : 0.18)

        color: "transparent"

        Item {
            id: content
            anchors.fill: parent
            anchors.margins: 6

            // --- utilisateur : a gauche, ou en haut
            Pill {
                id: userPill

                anchors.left: bar.vertical ? undefined : parent.left
                anchors.top: bar.vertical ? parent.top : undefined
                anchors.horizontalCenter: bar.vertical ? parent.horizontalCenter : undefined
                anchors.verticalCenter: bar.vertical ? undefined : parent.verticalCenter
                width: bar.vertical ? bar.pillThickness : implicitWidth
                height: bar.vertical ? implicitHeight : bar.pillThickness

                Hoverable {
                    anchors.centerIn: parent

                    User {
                        size: Config.barSize * (bar.vertical ? 0.45 : 0.34)
                    }
                }
            }

            // --- statistiques systeme, contre la bulle utilisateur
            Pill {
                id: statsPill

                anchors.left: bar.vertical ? undefined : userPill.right
                anchors.leftMargin: bar.vertical ? 0 : 8
                anchors.top: bar.vertical ? userPill.bottom : undefined
                anchors.topMargin: bar.vertical ? 8 : 0
                anchors.horizontalCenter: bar.vertical ? parent.horizontalCenter : undefined
                anchors.verticalCenter: bar.vertical ? undefined : parent.verticalCenter
                width: bar.vertical ? bar.pillThickness : implicitWidth
                height: bar.vertical ? implicitHeight : bar.pillThickness

                Stats {
                    anchors.centerIn: parent
                    labelSize: bar.labelSize
                    size: Config.barSize * 0.22
                }
            }

            // --- workspaces : toujours au centre
            Pill {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: bar.vertical ? bar.pillThickness : implicitWidth
                height: bar.vertical ? implicitHeight : bar.pillThickness

                Workspaces { screen: bar.screen }
            }

            // --- etat systeme : permanent, a droite ou en bas
            Pill {
                id: statusPill

                anchors.right: bar.vertical ? undefined : parent.right
                anchors.bottom: bar.vertical ? parent.bottom : undefined
                anchors.horizontalCenter: bar.vertical ? parent.horizontalCenter : undefined
                anchors.verticalCenter: bar.vertical ? undefined : parent.verticalCenter
                width: bar.vertical ? bar.pillThickness : implicitWidth
                height: bar.vertical ? implicitHeight : bar.pillThickness

                // Grid plutot que Row ou Column : une seule declaration
                // couvre les deux orientations.
                Grid {
                    anchors.centerIn: parent
                    spacing: 14
                    columns: bar.vertical ? 1 : 5
                    horizontalItemAlignment: Grid.AlignHCenter
                    // centre plutot qu'aligne par le bas : les widgets n'ont
                    // plus tous la meme hauteur depuis que le reseau met ses
                    // deux debits a cote du glyphe
                    verticalItemAlignment: Grid.AlignVCenter

                    Hoverable {
                        Network {
                            size: Config.barSize * 0.2
                        }
                    }
                    Hoverable {
                        Bluetooth {
                            size: Config.barSize * 0.2
                        }
                    }
                    Hoverable {
                        Volume {
                            labelSize: bar.labelSize
                            size: Config.barSize * 0.2
                        }
                    }
                    Hoverable {
                        Battery {
                            labelSize: bar.labelSize
                            size: Config.barSize * 0.25
                        }
                    }
                    Hoverable {
                        Clock {
                            labelSize: bar.labelSize
                            size: Config.barSize * 0.28
                        }
                    }
                }
            }

            // --- tray : transitoire, dans sa propre bulle avant l'etat
            // systeme. Separe parce que son contenu va et vient avec les
            // applis, et qu'il n'a qu'une ligne la ou les autres en ont deux.
            Pill {
                id: trayPill

                // pas d'item en tray : la bulle disparait au lieu de
                // laisser une capsule vide flotter dans la barre
                visible: trayWidget.visible

                anchors.right: bar.vertical ? undefined : statusPill.left
                anchors.rightMargin: bar.vertical ? 0 : 8
                anchors.bottom: bar.vertical ? statusPill.top : undefined
                anchors.bottomMargin: bar.vertical ? 8 : 0
                anchors.horizontalCenter: bar.vertical ? parent.horizontalCenter : undefined
                anchors.verticalCenter: bar.vertical ? undefined : parent.verticalCenter
                width: bar.vertical ? bar.pillThickness : implicitWidth
                height: bar.vertical ? implicitHeight : bar.pillThickness

                Tray {
                    id: trayWidget
                    anchors.centerIn: parent
                    size: Config.barSize * 0.22
                    window: bar
                }
            }
        }
    }
}
