import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.services

// Menu (ou sous-menu) redessine aux couleurs de la barre.
//
// On ne passe pas par SystemTrayItem.display(), qui ouvre un menu Qt natif
// impossible a themer : on lit l'arbre via QsMenuOpener et on le dessine.
//
// Le composant est recursif : QsMenuEntry herite de QsMenuHandle, donc une
// entree a enfants est elle-meme un menu, qu'on rouvre dans une instance
// de ce meme fichier.
PopupWindow {
    id: root

    // QsMenuHandle : soit SystemTrayItem.menu, soit une entree a enfants
    property var menuHandle: null
    property Item anchorItem: null
    // un sous-menu s'ouvre a droite de sa ligne, pas sous une icone
    property bool submenu: false
    // permet a une entree feuille de refermer toute la chaine
    property var parentMenu: null

    property int padding: 6
    property int rowHeight: 26

    // le popup courant parmi les sous-menus de CE menu
    property var currentSub: null

    // QML refuse qu'un type s'instancie lui-meme dans son arbre statique
    // ("TrayMenu is instantiated recursively") : il detecte le cycle au
    // chargement sans pouvoir savoir qu'il s'arretera. On casse le cycle en
    // chargeant le composant par URL a la demande — la recursion devient un
    // fait d'execution, et les sous-menus ne sont crees que si on les ouvre.
    property var subComponent: null

    function showSub(sub) {
        if (root.currentSub && root.currentSub !== sub)
            root.currentSub.visible = false
        root.currentSub = sub
        sub.visible = true
    }

    function closeSub() {
        if (root.currentSub) {
            root.currentSub.visible = false
            root.currentSub = null
        }
    }

    // remonte toute la chaine : une action declenchee ferme le menu entier
    function closeChain() {
        root.closeSub()
        root.visible = false
        if (root.parentMenu)
            root.parentMenu.closeChain()
    }

    anchor.item: root.anchorItem
    anchor.edges: root.submenu ? Edges.Right : Edges.Bottom
    anchor.gravity: root.submenu ? Edges.Right : Edges.Bottom
    // Place insuffisante du cote demande : le compositeur bascule le popup
    // de l'autre cote (FlipX/FlipY) plutot que de le laisser deborder ou
    // recouvrir son parent. Slide en dernier recours, pour le cas ou aucun
    // des deux cotes ne suffit.
    anchor.adjustment: PopupAdjustment.Flip | PopupAdjustment.Slide
    // Un seul grab pour toute la chaine, detenu par le menu racine : deux
    // grabs simultanes sont interdits par le protocole, et le grab du parent
    // couvre deja ses enfants.
    grabFocus: !root.submenu

    implicitWidth: surface.implicitWidth
    implicitHeight: surface.implicitHeight
    color: "transparent"
    visible: false

    // fermer un menu ferme ses sous-menus
    onVisibleChanged: if (!visible) root.closeSub()

    QsMenuOpener {
        id: opener
        menu: root.menuHandle
    }

    Rectangle {
        id: surface
        anchors.fill: parent

        // meme logique que Pill : la taille vient du contenu
        implicitWidth: Math.max(160, column.implicitWidth + root.padding * 2)
        implicitHeight: column.implicitHeight + root.padding * 2

        color: Theme.overlay
        radius: 10
        border.color: Qt.alpha(Theme.glow, 0.3)
        border.width: 1

        ColumnLayout {
            id: column
            anchors.fill: parent
            anchors.margins: root.padding
            spacing: 0

            Repeater {
                model: opener.children

                Item {
                    id: row
                    required property QsMenuEntry modelData

                    Layout.fillWidth: true
                    implicitWidth: row.modelData.isSeparator
                        ? 0
                        : label.implicitWidth + root.rowHeight * 2
                    implicitHeight: row.modelData.isSeparator ? 9 : root.rowHeight

                    // --- sous-menu de cette ligne, cree au premier deroulement
                    property var subInstance: null

                    function ensureSub() {
                        if (row.subInstance)
                            return row.subInstance
                        if (!root.subComponent)
                            root.subComponent = Qt.createComponent("TrayMenu.qml")
                        row.subInstance = root.subComponent.createObject(row, {
                            submenu: true,
                            parentMenu: root,
                            menuHandle: row.modelData,
                            anchorItem: row
                        })
                        // le popup ne previent pas quand sway le ferme
                        row.subInstance.visibleChanged.connect(function () {
                            if (!row.subInstance.visible && root.currentSub === row.subInstance)
                                root.currentSub = null
                        })
                        return row.subInstance
                    }

                    // --- separateur
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 1
                        color: Qt.alpha(Theme.glow, 0.25)
                        visible: row.modelData.isSeparator
                    }

                    // --- entree cliquable
                    Rectangle {
                        anchors.fill: parent
                        visible: !row.modelData.isSeparator
                        radius: 6
                        color: hover.hovered && row.modelData.enabled
                            ? Qt.alpha(Theme.glow, 0.12)
                            : "transparent"

                        HoverHandler {
                            id: hover
                            // survol d'une ligne a enfants : on deroule.
                            // survol d'une ligne simple : on referme le
                            // sous-menu voisin, comme un menu natif.
                            onHoveredChanged: {
                                if (!hovered || !row.modelData.enabled)
                                    return
                                if (row.modelData.hasChildren)
                                    root.showSub(row.ensureSub())
                                else
                                    root.closeSub()
                            }
                        }

                        TapHandler {
                            enabled: row.modelData.enabled
                            onTapped: {
                                if (row.modelData.hasChildren) {
                                    root.showSub(row.ensureSub())
                                    return
                                }
                                // "triggered" est un signal, mais c'est bien
                                // lui qui declenche l'action cote D-Bus
                                row.modelData.triggered()
                                root.closeChain()
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            Rectangle {
                                visible: row.modelData.buttonType !== QsMenuButtonType.None
                                implicitWidth: 12
                                implicitHeight: 12
                                radius: row.modelData.buttonType === QsMenuButtonType.RadioButton
                                    ? width / 2
                                    : 3
                                color: row.modelData.checkState === Qt.Checked
                                    ? Theme.accent
                                    : "transparent"
                                border.color: Qt.alpha(Theme.glow, 0.5)
                                border.width: 1
                            }

                            IconImage {
                                visible: row.modelData.icon !== ""
                                source: row.modelData.icon
                                implicitSize: 16
                            }

                            Text {
                                id: label
                                Layout.fillWidth: true
                                // les libelles D-Bus portent les mnemoniques
                                // GTK ("_Quitter") : on retire le souligne
                                text: row.modelData.text.replace(/_([^_])/, "$1")
                                color: row.modelData.enabled ? Theme.fg : Theme.dim
                                font.family: Theme.font
                                font.pixelSize: 13
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: row.modelData.hasChildren
                                text: "›"
                                color: Theme.muted
                                font.family: Theme.font
                                font.pixelSize: 15
                            }
                        }
                    }
                }
            }
        }
    }
}
