import QtQuick
import qs.services

// Enveloppe qui donne un retour visuel au survol, sans rien changer a la
// mise en page : le fond deborde du contenu par des marges NEGATIVES, donc
// la taille implicite reste celle de l'enfant. Emballer un widget existant
// ne deplace donc rien autour de lui.
//
// Contrat, comme Pill : un seul enfant direct, qui declare sa taille.
Item {
    id: root

    default property alias content: inner.data
    // debordement du fond au-dela du contenu
    property int padding: 6
    property bool interactive: true

    signal clicked(var event)

    readonly property bool hovered: hover.hovered && root.interactive

    implicitWidth: inner.children[0]?.implicitWidth ?? 0
    implicitHeight: inner.children[0]?.implicitHeight ?? 0

    Rectangle {
        anchors.fill: parent
        anchors.margins: -root.padding
        radius: Config.rounded ? height / 2 : 4
        color: root.hovered ? Qt.alpha(Theme.glow, 0.12) : "transparent"

        Behavior on color { ColorAnimation { duration: 120 } }
    }

    Item {
        id: inner
        anchors.fill: parent
    }

    HoverHandler {
        id: hover
        enabled: root.interactive
        // la main indique que quelque chose repond au clic
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        enabled: root.interactive
        onTapped: event => root.clicked(event)
    }
}
