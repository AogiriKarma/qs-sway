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
        // page du panneau ouverte dans la bulle d'etat ("" = repliee)
        property string panel: ""
        readonly property bool expanded: bar.panel !== "" || statusPill.morphing

        // Une surface layer-shell ne dessine rien hors de ses limites : pour
        // que la bulle puisse s'etendre, la fenetre doit deja etre grande.
        // Elle couvre tout l'ecran des qu'une page est ouverte, ce qui permet
        // aussi d'attraper le clic exterieur qui referme.
        anchors {
            top: true
            left: true
            right: !bar.vertical || bar.expanded
            bottom: bar.vertical || bar.expanded
        }
        implicitHeight: bar.vertical ? 0 : Config.barSize
        implicitWidth: bar.vertical ? Config.barSize : 0

        // ...mais elle ne reserve jamais que l'epaisseur de la barre : les
        // fenetres ne bougent pas d'un pixel quand le panneau s'ouvre.
        exclusiveZone: Config.barSize

        // Sans masque, une fenetre plein ecran transparente avalerait tous
        // les clics. On ne rend cliquable que les bulles — et tout l'ecran
        // quand une page est ouverte, pour que le clic exterieur la ferme.
        mask: Region {
            Region { item: bar.expanded ? null : userPill }
            Region { item: bar.expanded ? null : statsPill }
            Region { item: bar.expanded ? null : workspacesPill }
            Region { item: bar.expanded ? null : trayPill }
            Region { item: bar.expanded ? null : statusPill }
            Region { item: bar.expanded ? scrim : null }
        }

        // le clavier n'est pris que quand une page est ouverte, jamais sinon
        focusable: bar.panel !== ""

        // epaisseur des bulles, dans la dimension contrainte
        readonly property real pillThickness: Config.barSize * (bar.vertical ? 0.8 : 0.6)
        readonly property real labelSize: Config.barSize * (bar.vertical ? 0.22 : 0.18)

        color: "transparent"

        // --- clic exterieur : referme la page ouverte
        MouseArea {
            id: scrim
            anchors.fill: parent
            enabled: bar.panel !== ""
            onClicked: bar.panel = ""
        }

        Item {
            id: strip
            // la bande de la barre proprement dite ; la fenetre est plus
            // grande, mais les bulles se positionnent par rapport a elle
            anchors.top: parent.top
            anchors.left: parent.left
            width: bar.vertical ? Config.barSize : parent.width
            height: bar.vertical ? parent.height : Config.barSize

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
                        tooltip: bar.panel === "" ? userWidget.details : ""

                        User {
                            id: userWidget
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
                    id: workspacesPill

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: bar.vertical ? bar.pillThickness : implicitWidth
                    height: bar.vertical ? implicitHeight : bar.pillThickness

                    Workspaces { screen: bar.screen }
                }

                // --- etat systeme : la bulle qui se transforme en panneau
                Pill {
                    id: statusPill

                    // hauteur animee : c'est elle qui porte le morphing
                    readonly property real collapsed: bar.pillThickness
                    readonly property real expandedSize: statusContent.implicitHeight + padding * 2
                    readonly property bool morphing: heightAnim.running || widthAnim.running

                    anchors.right: bar.vertical ? undefined : parent.right
                    anchors.bottom: bar.vertical ? parent.bottom : undefined
                    anchors.horizontalCenter: bar.vertical ? parent.horizontalCenter : undefined
                    // ancre par le haut plutot que centree : la bulle doit
                    // grandir vers le bas, pas des deux cotes
                    anchors.top: bar.vertical ? undefined : parent.top
                    anchors.topMargin: bar.vertical ? 0 : (Config.barSize - 12 - bar.pillThickness) / 2

                    width: statusContent.implicitWidth + padding * 2
                    height: bar.panel === "" ? statusPill.collapsed : statusPill.expandedSize

                    // pendant l'animation, le contenu qui depasse est coupe
                    clip: true

                    Behavior on width { NumberAnimation { id: widthAnim; duration: 220; easing.type: Easing.OutCubic } }
                    Behavior on height { NumberAnimation { id: heightAnim; duration: 220; easing.type: Easing.OutCubic } }

                    Item {
                        id: statusContent

                        implicitWidth: Math.max(statusRow.implicitWidth, panelLoader.item?.implicitWidth ?? 0)
                        implicitHeight: (bar.pillThickness - statusPill.padding * 2)
                            + (panelLoader.item ? panelLoader.item.implicitHeight + 16 : 0)
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: implicitWidth

                        Grid {
                            id: statusRow
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: (bar.pillThickness - statusPill.padding * 2 - height) / 2
                            spacing: 14
                            columns: bar.vertical ? 1 : 5
                            horizontalItemAlignment: Grid.AlignHCenter
                            verticalItemAlignment: Grid.AlignVCenter

                            Hoverable {
                                tooltip: bar.panel === "" ? networkWidget.details : ""
                                onClicked: bar.panel = bar.panel === "Network" ? "" : "Network"

                                Network {
                                    id: networkWidget
                                    size: Config.barSize * 0.2
                                }
                            }
                            Hoverable {
                                tooltip: bar.panel === "" ? bluetoothWidget.details : ""
                                onClicked: bar.panel = bar.panel === "Bluetooth" ? "" : "Bluetooth"

                                Bluetooth {
                                    id: bluetoothWidget
                                    size: Config.barSize * 0.2
                                }
                            }
                            Hoverable {
                                tooltip: bar.panel === "" ? volumeWidget.details : ""
                                onClicked: bar.panel = bar.panel === "Volume" ? "" : "Volume"

                                Volume {
                                    id: volumeWidget
                                    labelSize: bar.labelSize
                                    size: Config.barSize * 0.2
                                }
                            }
                            Hoverable {
                                tooltip: bar.panel === "" ? batteryWidget.details : ""
                                onClicked: bar.panel = bar.panel === "Battery" ? "" : "Battery"

                                Battery {
                                    id: batteryWidget
                                    labelSize: bar.labelSize
                                    size: Config.barSize * 0.25
                                }
                            }
                            Hoverable {
                                tooltip: bar.panel === "" ? clockWidget.details : ""
                                onClicked: bar.panel = bar.panel === "Calendar" ? "" : "Calendar"

                                Clock {
                                    id: clockWidget
                                    labelSize: bar.labelSize
                                    size: Config.barSize * 0.28
                                }
                            }
                        }

                        Loader {
                            id: panelLoader
                            anchors.top: statusRow.bottom
                            anchors.topMargin: 16
                            anchors.horizontalCenter: parent.horizontalCenter
                            // charge par URL : les pages n'ont pas a etre
                            // declarees dans le qmldir
                            source: bar.panel ? "widgets/panels/" + bar.panel + ".qml" : ""
                        }
                    }
                }

                // --- tray : transitoire, dans sa propre bulle
                Pill {
                    id: trayPill

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
}
