import QtQuick
import qs.services

Rectangle {
    id: root

    default property alias content: inner.data
    property int padding: 14
    // barre laterale : c'est la hauteur qui suit le contenu, pas la largeur
    readonly property bool vertical: Config.vertical

    color: Theme.surface
    radius: Config.rounded ? (root.vertical ? width : height) / 2 : 0
    border.color: Qt.alpha(Theme.glow, 0.3)
    border.width: 1

    implicitWidth: root.vertical
        ? 0
        : (inner.children[0]?.implicitWidth ?? 0) + padding * 2
    implicitHeight: root.vertical
        ? (inner.children[0]?.implicitHeight ?? 0) + padding * 2
        : 0

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: root.vertical ? root.padding / 2 : root.padding
    }
}