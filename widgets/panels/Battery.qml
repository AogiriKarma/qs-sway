import Quickshell
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import qs.services

// Page batterie, d'apres le schema : les trois profils d'alimentation en
// haut, une grande jauge dessinee au milieu, l'autonomie en dessous.
//
// Les profils passent par power-profiles-daemon, expose ici par
// PowerProfiles. L'ecriture est autorisee par polkit pour la session
// active : rien a configurer, contrairement a un acces direct a
// /sys/firmware/acpi/platform_profile, reserve a root.
ColumnLayout {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool charging: root.device?.state === UPowerDeviceState.Charging
    readonly property real percentage: root.device?.percentage ?? 0

    // secondes -> "1h47" ; "" tant qu'UPower n'a pas de debit stable
    function formatDuration(seconds) {
        if (!seconds || seconds <= 0)
            return ""
        const h = Math.floor(seconds / 3600)
        const m = Math.round((seconds % 3600) / 60)
        return h > 0 ? h + "h" + String(m).padStart(2, "0") : m + " min"
    }

    readonly property string remaining: root.formatDuration(
        root.charging ? root.device?.timeToFull : root.device?.timeToEmpty)

    spacing: 16

    // ---------- profils d'alimentation
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 18

        Repeater {
            model: [
                { glyph: "󰌪", value: PowerProfile.PowerSaver, name: "Power saver" },
                { glyph: "󰗑", value: PowerProfile.Balanced, name: "Balanced" },
                { glyph: "󰉁", value: PowerProfile.Performance, name: "Performance" }
            ]

            Rectangle {
                id: profile
                required property var modelData
                readonly property bool current: PowerProfiles.profile === profile.modelData.value
                // certaines machines n'ont pas de mode performance
                readonly property bool available: profile.modelData.value !== PowerProfile.Performance
                    || PowerProfiles.hasPerformanceProfile

                implicitWidth: 44
                implicitHeight: 44
                radius: Config.rounded ? width / 2 : 6
                color: profile.current ? Qt.alpha(Theme.glow, 0.22)
                    : profileHover.hovered && profile.available ? Qt.alpha(Theme.glow, 0.1)
                    : "transparent"
                border.color: profile.current ? Theme.accent : Qt.alpha(Theme.glow, 0.3)
                border.width: profile.current ? 2 : 1
                opacity: profile.available ? 1 : 0.35

                Behavior on color { ColorAnimation { duration: 120 } }

                HoverHandler { id: profileHover; enabled: profile.available }
                TapHandler {
                    enabled: profile.available
                    onTapped: PowerProfiles.profile = profile.modelData.value
                }

                Text {
                    anchors.centerIn: parent
                    text: profile.modelData.glyph
                    color: profile.current ? Theme.fg : Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 20
                }
            }
        }
    }

    // ---------- jauge : une batterie dessinee, borne a gauche
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 0

        // la borne, plus petite que le corps
        Rectangle {
            implicitWidth: 7
            implicitHeight: 22
            topLeftRadius: 3
            bottomLeftRadius: 3
            color: Qt.alpha(Theme.glow, 0.5)
        }

        Rectangle {
            id: body
            implicitWidth: 210
            implicitHeight: 54
            radius: Config.rounded ? 8 : 0
            color: "transparent"
            border.color: Qt.alpha(Theme.glow, 0.5)
            border.width: 2

            // le remplissage suit le niveau reel
            Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 4
                width: Math.max(0, (body.width - 8) * root.percentage)
                height: body.height - 8
                radius: Config.rounded ? 5 : 0
                color: root.charging ? Theme.special
                    : root.percentage <= 0.2 ? Theme.danger
                    : Theme.accent
                opacity: 0.85

                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            // Le pourcentage est ecrit PAR-DESSUS le remplissage, en couleur
            // du fond : sur la partie pleine il se detache en negatif, sur la
            // partie vide il resterait invisible. On le laisse donc sur le
            // fond sombre, qui contraste avec les deux.
            Text {
                anchors.centerIn: parent
                text: Math.round(root.percentage * 100) + "%"
                color: Theme.overlay
                font.family: Theme.fontMono
                font.pixelSize: 26
            }
        }
    }

    // ---------- autonomie
    Text {
        Layout.alignment: Qt.AlignHCenter
        text: {
            if (!root.remaining)
                return root.charging ? "Charging..." : ""
            return root.charging ? "Charging... " + root.remaining + " left"
                : root.remaining + " left"
        }
        color: Theme.muted
        font.family: Theme.font
        font.pixelSize: 12
    }
}
