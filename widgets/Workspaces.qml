import Quickshell
import Quickshell.I3
import Quickshell.Widgets
import QtQuick
import qs.services

Row {
    id: root

    property int count: 10
    property ShellScreen screen
    readonly property I3Monitor monitor: I3.monitorFor(screen)

    spacing: 6
    anchors.centerIn: parent

    Repeater {
        model: root.count

        Rectangle {
            required property int index
            property int wsId: index + 1
            property bool active: root.monitor?.activeWorkspace?.number === wsId

            property var apps: SwayTree.wsApps[wsId] ?? []
            property string appId: apps[0] ?? ""
            property string iconName: appId
                ? (DesktopEntries.applications.values, DesktopEntries.heuristicLookup(appId)?.icon ?? "")
                : ""

            width: 24
            height: 24
            radius: width / 2
            // actif : pas de remplissage, juste le contour — sinon
            // l'aplat clair avale les icones, claires elles aussi
            color: Theme.dim
            border.color: Theme.accent
            border.width: active ? 2 : 0
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.width { NumberAnimation { duration: 120 } }

            MouseArea {
                anchors.fill: parent
                onClicked: I3.dispatch(`workspace number ${wsId}`)
            }

            Text {
                anchors.centerIn: parent
                text: wsId
                // plus de fond clair sur l'actif : le numero reste clair
                color: Theme.accent
                font.family: Theme.font
                // l'icone prend sa place : les icones monochromes ont trop
                // de negatif pour que le numero reste lisible dessous
                visible: !iconName
            }
            IconImage {
                anchors.centerIn: parent
                source: iconName ? Quickshell.iconPath(iconName, true) : ""
                implicitSize: parent.width * 0.75
                visible: source != ""
            }

        }
    }
}