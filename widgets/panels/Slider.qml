import QtQuick
import qs.services

// Curseur minimal, dessine a la main plutot qu'emprunte a QtQuick.Controls :
// le style par defaut des Controls ne suit pas Theme, et l'habiller couterait
// plus que de le dessiner.
Item {
    id: root

    property real value: 0
    property real maximum: 1
    // emis en continu pendant le glissement, pas seulement au relachement
    signal moved(real value)

    implicitWidth: 150
    implicitHeight: 6

    function positionToValue(x) {
        return Math.max(0, Math.min(1, x / root.width)) * root.maximum
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Qt.alpha(Theme.glow, 0.15)
    }

    Rectangle {
        width: parent.width * Math.max(0, Math.min(1, root.value / root.maximum))
        height: parent.height
        radius: height / 2
        color: Theme.accent
    }

    Rectangle {
        x: parent.width * Math.max(0, Math.min(1, root.value / root.maximum)) - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: 12
        height: 12
        radius: 6
        color: Theme.accent
        visible: area.containsMouse || area.pressed
    }

    MouseArea {
        id: area
        anchors.fill: parent
        // zone de saisie plus haute que la barre : viser 6 px est penible
        anchors.topMargin: -8
        anchors.bottomMargin: -8
        hoverEnabled: true
        onPressed: event => root.moved(root.positionToValue(event.x))
        onPositionChanged: event => {
            if (area.pressed)
                root.moved(root.positionToValue(event.x))
        }
    }
}
