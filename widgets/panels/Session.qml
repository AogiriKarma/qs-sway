import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services

// Page session : veille, extinction, redemarrage en trois ronds, puis la
// deconnexion en pleine largeur dessous.
//
// Quickshell.execDetached lance la commande sans garder de processus
// enfant rattache au shell — ce qui compte ici : `systemctl poweroff` tue
// la barre elle-meme, et un Process suivi laisserait un objet orphelin.
ColumnLayout {
    id: root

    // action survolee, pour l'afficher en toutes lettres
    property string hovered: ""

    spacing: 12

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 16

        Repeater {
            model: [
                { glyph: "󰤄", name: "Suspend", command: ["systemctl", "suspend"], danger: false },
                { glyph: "󰐥", name: "Power off", command: ["systemctl", "poweroff"], danger: true },
                { glyph: "󰑓", name: "Reboot", command: ["systemctl", "reboot"], danger: true }
            ]

            Rectangle {
                id: action
                required property var modelData

                implicitWidth: 46
                implicitHeight: 46
                radius: Config.rounded ? width / 2 : 8
                color: actionHover.hovered
                    ? Qt.alpha(action.modelData.danger ? Theme.danger : Theme.glow, 0.22)
                    : "transparent"
                border.color: actionHover.hovered && action.modelData.danger
                    ? Theme.danger
                    : Qt.alpha(Theme.glow, 0.3)
                border.width: 1

                Behavior on color { ColorAnimation { duration: 120 } }

                HoverHandler {
                    id: actionHover
                    cursorShape: Qt.PointingHandCursor
                    onHoveredChanged: root.hovered = hovered ? action.modelData.name : ""
                }
                TapHandler { onTapped: Quickshell.execDetached(action.modelData.command) }

                Text {
                    anchors.centerIn: parent
                    text: action.modelData.glyph
                    color: actionHover.hovered && action.modelData.danger ? Theme.danger : Theme.fg
                    font.family: Theme.font
                    font.pixelSize: 20
                }
            }
        }
    }

    // le libelle de l'action survolee : trois ronds sans texte laissent
    // deviner, et se tromper ici coute une session
    Text {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredHeight: 14
        text: root.hovered
        color: Theme.muted
        font.family: Theme.font
        font.pixelSize: 11
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 28
        radius: Config.rounded ? 14 : 4
        color: outHover.hovered ? Qt.alpha(Theme.glow, 0.18) : Qt.alpha(Theme.glow, 0.08)
        border.color: Qt.alpha(Theme.glow, 0.3)
        border.width: 1

        HoverHandler { id: outHover; cursorShape: Qt.PointingHandCursor }
        // swaymsg exit termine la session sway ; systemctl ne connait pas
        // les sessions graphiques d'un compositeur lance a la main
        TapHandler { onTapped: Quickshell.execDetached(["swaymsg", "exit"]) }

        RowLayout {
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: "󰍃"
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: 14
            }

            Text {
                text: "Log out"
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: 12
            }
        }
    }
}
