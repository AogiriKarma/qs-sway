import Quickshell
import QtQuick
import qs.services

// Infobulle : une fenetre popup sans grab, qui ne prend jamais le focus
// et ne reagit a aucun clic. Elle sort sous le widget survole, ou a sa
// droite en barre laterale.
PopupWindow {
    id: root

    property string text: ""
    property Item anchorItem: null

    anchor.item: root.anchorItem
    anchor.edges: Config.vertical ? Edges.Right : Edges.Bottom
    anchor.gravity: Config.vertical ? Edges.Right : Edges.Bottom
    // place insuffisante d'un cote : le compositeur bascule ou fait glisser
    anchor.adjustment: PopupAdjustment.Flip | PopupAdjustment.Slide
    // Un grab volerait le focus a l'application active, pour une simple
    // info au survol. Et sans grab, aucun clic n'est detourne.
    grabFocus: false

    implicitWidth: surface.implicitWidth
    implicitHeight: surface.implicitHeight
    color: "transparent"
    visible: false

    Rectangle {
        id: surface
        anchors.fill: parent

        implicitWidth: label.implicitWidth + 20
        implicitHeight: label.implicitHeight + 12

        color: Theme.overlay
        radius: Config.rounded ? 8 : 0
        border.color: Qt.alpha(Theme.glow, 0.3)
        border.width: 1

        Text {
            id: label
            anchors.centerIn: parent
            text: root.text
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: 13
            // les infobulles multilignes sont centrees, comme le bloc
            horizontalAlignment: Text.AlignHCenter
            lineHeight: 1.15
        }
    }
}
