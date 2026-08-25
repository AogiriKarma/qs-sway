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
        // que la bulle puisse s'etendre, la fenetre grandit avec elle.
        //
        // PIEGE : on ne touche PAS aux ancres. Une surface ancree aux quatre
        // bords ne peut pas reserver de zone exclusive — le protocole
        // l'interdit — et sway rendrait alors les 80 px aux fenetres, qui
        // sauteraient a chaque ouverture. On reste donc sur une bande ancree
        // a trois bords, et seule sa taille change.
        anchors {
            top: true
            left: true
            right: !bar.vertical
            bottom: bar.vertical
        }
        implicitHeight: bar.vertical ? 0 : (bar.expanded ? bar.screen.height : Config.barSize)
        implicitWidth: bar.vertical ? (bar.expanded ? bar.screen.width : Config.barSize) : 0

        // ...mais elle ne reserve jamais que l'epaisseur de la barre : les
        // fenetres ne bougent pas d'un pixel quand le panneau s'ouvre.
        exclusiveZone: Config.barSize

        // Sans masque, une surface transparente de la hauteur de l'ecran
        // avalerait tous les clics destines aux fenetres. On ne rend donc
        // cliquable que les bulles — et toute la surface quand une page est
        // ouverte, pour que le clic exterieur la referme.
        //
        // PIEGE : basculer `item` a l'interieur des sous-regions ne suffit
        // pas, le masque n'etait pas recalcule et restait fige sur la forme
        // repliee. On echange l'objet Region entier, ce qui force la mise a
        // jour.
        mask: bar.expanded ? fullMask : pillsMask

        Region {
            id: fullMask
            item: scrim
        }

        Region {
            id: pillsMask
            Region { item: userPill }
            Region { item: statsPill }
            Region { item: workspacesPill }
            Region { item: trayPill }
            Region { item: statusPill }
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
            onPressed: console.log("TRACE| voile: press recu")
            onClicked: bar.panel = ""
        }

        // PIEGE : ne pas enfermer les bulles dans une bande de la hauteur de
        // la barre. Qt ne delivre aucun evenement a un enfant qui deborde de
        // son parent — la bulle depliee etait dessinee mais pas cliquable
        // sous 80 px. Le conteneur couvre donc toute la fenetre, et c'est un
        // decalage calcule qui place les bulles dans la bande visible.
        Item {
            id: content
            anchors.fill: parent
            anchors.margins: 6

            // decalage vertical (ou horizontal) pour centrer une bulle dans
            // la bande de la barre, marges comprises
            readonly property real inset: (Config.barSize - 12 - bar.pillThickness) / 2


                // --- utilisateur : a gauche, ou en haut
                Pill {
                    id: userPill

                    anchors.left: bar.vertical ? parent.left : undefined
                    anchors.leftMargin: bar.vertical ? content.inset : 0
                    anchors.top: parent.top
                    anchors.topMargin: bar.vertical ? 0 : content.inset
                    width: bar.vertical ? bar.pillThickness : implicitWidth
                    height: bar.vertical ? implicitHeight : bar.pillThickness

                    Hoverable {
                        anchors.centerIn: parent
                        interactive: false

                        User {
                            id: userWidget
                            size: Config.barSize * (bar.vertical ? 0.45 : 0.34)
                        }
                    }
                }

                // --- statistiques systeme, contre la bulle utilisateur
                Pill {
                    id: statsPill

                    anchors.left: bar.vertical ? parent.left : userPill.right
                    anchors.leftMargin: bar.vertical ? content.inset : 8
                    anchors.top: bar.vertical ? userPill.bottom : parent.top
                    anchors.topMargin: bar.vertical ? 8 : content.inset
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

                    anchors.horizontalCenter: bar.vertical ? undefined : parent.horizontalCenter
                    anchors.left: bar.vertical ? parent.left : undefined
                    anchors.leftMargin: bar.vertical ? content.inset : 0
                    anchors.verticalCenter: bar.vertical ? parent.verticalCenter : undefined
                    anchors.top: bar.vertical ? undefined : parent.top
                    anchors.topMargin: bar.vertical ? 0 : content.inset
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
                    anchors.left: bar.vertical ? parent.left : undefined
                    anchors.leftMargin: bar.vertical ? content.inset : 0
                    // ancree par le haut : la bulle grandit vers le bas,
                    // pas des deux cotes
                    anchors.top: bar.vertical ? undefined : parent.top
                    anchors.topMargin: bar.vertical ? 0 : content.inset

                    width: statusContent.implicitWidth + padding * 2
                    height: bar.panel === "" ? statusPill.collapsed : statusPill.expandedSize

                    // Une bulle fine peut etre translucide : elle est posee sur
                    // le fond d'ecran. Un panneau de 250 px recouvre des
                    // fenetres, et leur texte transparaitrait au travers — le
                    // fond devient donc opaque en se depliant.
                    color: bar.panel === "" ? Theme.surface : Theme.overlay

                    // pendant l'animation, le contenu qui depasse est coupe
                    clip: true

                    Behavior on color { ColorAnimation { duration: 220 } }
                    Behavior on width { NumberAnimation { id: widthAnim; duration: 220; easing.type: Easing.OutCubic } }
                    Behavior on height { NumberAnimation { id: heightAnim; duration: 220; easing.type: Easing.OutCubic } }

                    // Un TapHandler traite l'evenement sans le consommer : sans
                    // cette MouseArea, chaque clic sur un bouton du panneau
                    // continuerait jusqu'au voile plein ecran, qui refermerait.
                    // Declaree APRES statusContent pour ne pas devenir
                    // children[0], dont Pill tire sa largeur ; z negatif pour
                    // rester sous les boutons.
                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        acceptedButtons: Qt.AllButtons
                        onClicked: {} // absorbe le clic, ne fait rien
                    }

                    Item {
                        id: statusContent

                        // largeur plancher quand une page est ouverte : une
                        // liste defilante ne propage pas la largeur de son
                        // contenu, et le panneau se retrouverait etrique
                        // Les pages sont un peu plus larges que la rangee de
                        // widgets : assez pour respirer, pas assez pour que
                        // la bulle paraisse changer de nature en s'ouvrant.
                        readonly property real pageWidth: statusRow.implicitWidth + 60

                        implicitWidth: bar.panel === "" ? statusRow.implicitWidth
                            : statusContent.pageWidth
                        implicitHeight: (bar.pillThickness - statusPill.padding * 2)
                            + (panelLoader.item ? panelLoader.item.implicitHeight + 25 : 0)
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: implicitWidth

                        Grid {
                            id: statusRow
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: (bar.pillThickness - statusPill.padding * 2 - height) / 2
                            spacing: 14
                            columns: bar.vertical ? 1 : 7
                            horizontalItemAlignment: Grid.AlignHCenter
                            verticalItemAlignment: Grid.AlignVCenter

                            Hoverable {
                                onClicked: bar.panel = bar.panel === "Network" ? "" : "Network"

                                Network {
                                    id: networkWidget
                                    size: Config.barSize * 0.2
                                }
                            }
                            Hoverable {
                                onClicked: bar.panel = bar.panel === "Bluetooth" ? "" : "Bluetooth"

                                Bluetooth {
                                    id: bluetoothWidget
                                    size: Config.barSize * 0.2
                                }
                            }
                            Hoverable {
                                onClicked: bar.panel = bar.panel === "Volume" ? "" : "Volume"

                                Volume {
                                    id: volumeWidget
                                    labelSize: bar.labelSize
                                    size: Config.barSize * 0.2
                                }
                            }
                            Hoverable {
                                onClicked: bar.panel = bar.panel === "Battery" ? "" : "Battery"

                                Battery {
                                    id: batteryWidget
                                    labelSize: bar.labelSize
                                    size: Config.barSize * 0.25
                                }
                            }
                            Hoverable {
                                onClicked: bar.panel = bar.panel === "Calendar" ? "" : "Calendar"

                                Clock {
                                    id: clockWidget
                                    labelSize: bar.labelSize
                                    size: Config.barSize * 0.28
                                }
                            }

                            // Separateur : le bouton d'alimentation n'a pas la
                            // meme nature que ses voisins — ils informent, il
                            // agit. Le trait dit ce qu'un simple espace ne
                            // dirait pas, et l'eloigne de l'horloge au passage.
                            Rectangle {
                                implicitWidth: 1
                                implicitHeight: Config.barSize * 0.3
                                color: Qt.alpha(Theme.glow, 0.25)
                                visible: !bar.vertical
                            }

                            // bouton d'alimentation : pas de widget dedie,
                            // il n'affiche aucun etat — juste une porte
                            // vers la page session
                            Hoverable {
                                onClicked: bar.panel = bar.panel === "Session" ? "" : "Session"

                                Text {
                                    text: "󰐥"
                                    color: Theme.fg
                                    font.family: Theme.font
                                    font.pixelSize: Config.barSize * 0.25
                                }
                            }
                        }

                        // Trait de separation entre la barre et la page, plus
                        // court que le panneau des deux cotes : une ligne
                        // pleine couperait la bulle en deux morceaux au lieu
                        // de marquer une transition.
                        Rectangle {
                            id: panelRule
                            visible: bar.panel !== ""
                            anchors.top: statusRow.bottom
                            anchors.topMargin: 12
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width - 48
                            height: 1
                            color: Qt.alpha(Theme.glow, 0.25)
                        }

                        Loader {
                            id: panelLoader
                            anchors.top: panelRule.bottom
                            anchors.topMargin: 12
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: statusContent.pageWidth
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
                    anchors.left: bar.vertical ? parent.left : undefined
                    anchors.leftMargin: bar.vertical ? content.inset : 0
                    anchors.top: bar.vertical ? undefined : parent.top
                    anchors.topMargin: bar.vertical ? 0 : content.inset
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
