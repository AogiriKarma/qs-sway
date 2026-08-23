import QtQuick
import qs.services

Rectangle {
    id: root

    default property alias content: inner.data
    property int padding: 14

    color: Theme.surface
    radius: height / 2
    border.color: Qt.alpha(Theme.glow, 0.3)
    border.width: 1

    implicitWidth: (inner.children[0]?.implicitWidth ?? 0) + padding * 2

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: root.padding
    }
}