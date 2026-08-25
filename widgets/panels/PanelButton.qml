import QtQuick
import qs.services

// Petit bouton des panneaux : un rectangle, un libelle, un survol.
Rectangle {
    id: root

    property string text: ""
    property bool enabled: true
    signal activated()

    implicitWidth: label.implicitWidth + 18
    implicitHeight: 22
    radius: Config.rounded ? height / 2 : 4
    color: !root.enabled ? "transparent"
        : hover.hovered ? Qt.alpha(Theme.glow, 0.2)
        : Qt.alpha(Theme.glow, 0.1)
    border.color: Qt.alpha(Theme.glow, root.enabled ? 0.3 : 0.15)
    border.width: 1

    HoverHandler { id: hover; enabled: root.enabled }
    TapHandler {
        enabled: root.enabled
        onTapped: root.activated()
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.enabled ? Theme.fg : Theme.dim
        font.family: Theme.font
        font.pixelSize: 11
    }
}
