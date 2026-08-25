import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import qs.services

// Reglages de charge. UPower ne sait que lire : les seuils et le mode de
// charge vivent dans /sys/class/power_supply/BAT0, ecrits directement.
//
// Ces fichiers appartiennent a root ; une regle udev
// (/etc/udev/rules.d/99-thinkpad-battery.rules) en donne l'ecriture au
// groupe de l'utilisateur. Sans elle, les boutons resteraient sans effet.
ColumnLayout {
    id: root

    readonly property string base: "/sys/class/power_supply/BAT0/"
    readonly property var device: UPower.displayDevice

    readonly property int startThreshold: parseInt(startFile.text()) || 0
    readonly property int endThreshold: parseInt(endFile.text()) || 100
    // "[auto] inhibit-charge force-discharge" : le mode actif est entre crochets
    readonly property string behaviour: {
        const m = /\[([a-z-]+)\]/.exec(behaviourFile.text() ?? "")
        return m ? m[1] : ""
    }

    readonly property real health: {
        const full = parseFloat(fullFile.text())
        const design = parseFloat(designFile.text())
        return design > 0 ? full / design : 0
    }

    function write(view, value) {
        view.setText(String(value))
        // relecture immediate : le noyau peut refuser ou ajuster la valeur
        // (un seuil de debut superieur au seuil de fin, par exemple)
        refresh.restart()
    }

    FileView { id: startFile; path: root.base + "charge_control_start_threshold"; blockLoading: true; printErrors: false }
    FileView { id: endFile; path: root.base + "charge_control_end_threshold"; blockLoading: true; printErrors: false }
    FileView { id: behaviourFile; path: root.base + "charge_behaviour"; blockLoading: true; printErrors: false }
    FileView { id: fullFile; path: root.base + "energy_full"; blockLoading: true; printErrors: false }
    FileView { id: designFile; path: root.base + "energy_full_design"; blockLoading: true; printErrors: false }
    FileView { id: cyclesFile; path: root.base + "cycle_count"; blockLoading: true; printErrors: false }

    Timer {
        id: refresh
        interval: 400
        repeat: false
        running: true
        onTriggered: {
            startFile.reload()
            endFile.reload()
            behaviourFile.reload()
            fullFile.reload()
            designFile.reload()
            cyclesFile.reload()
        }
    }

    spacing: 12

    // ---------- etat
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Text {
            Layout.fillWidth: true
            text: Math.round((root.device?.percentage ?? 0) * 100) + "% — "
                + (root.device?.state === UPowerDeviceState.Charging ? "charging" : "on battery")
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: 13
            font.bold: true
        }
    }

    Repeater {
        model: [
            { key: "Health", value: Math.round(root.health * 100) + "%" },
            { key: "Cycles", value: cyclesFile.text().trim() || "—" },
            { key: "Charge limit", value: root.startThreshold + "–" + root.endThreshold + "%" }
        ]

        RowLayout {
            id: line
            required property var modelData
            Layout.fillWidth: true
            spacing: 10

            Text {
                Layout.preferredWidth: 84
                text: line.modelData.key
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 11
            }

            Text {
                Layout.fillWidth: true
                text: line.modelData.value
                color: Theme.fg
                font.family: Theme.fontMono
                font.pixelSize: 11
            }
        }
    }

    Rectangle { Layout.fillWidth: true; height: 1; color: Qt.alpha(Theme.glow, 0.2) }

    // ---------- seuil de fin de charge
    Text {
        text: "Stop charging at " + root.endThreshold + "%"
        color: Theme.muted
        font.family: Theme.font
        font.pixelSize: 11
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Slider {
            Layout.fillWidth: true
            maximum: 100
            value: root.endThreshold
            // Arrondi a 5 : le firmware ThinkPad n'a pas la finesse du
            // pixel, et viser 73 % n'a aucun sens pratique.
            onMoved: v => root.write(endFile, Math.max(40, Math.round(v / 5) * 5))
        }

        PanelButton {
            text: "80%"
            onActivated: root.write(endFile, 80)
        }

        PanelButton {
            text: "100%"
            onActivated: root.write(endFile, 100)
        }
    }

    // ---------- mode de charge
    Text {
        text: "Charge behaviour"
        color: Theme.muted
        font.family: Theme.font
        font.pixelSize: 11
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Repeater {
            model: [
                { id: "auto", label: "Auto" },
                { id: "inhibit-charge", label: "Pause" },
                { id: "force-discharge", label: "Discharge" }
            ]

            Rectangle {
                id: mode
                required property var modelData
                readonly property bool current: root.behaviour === mode.modelData.id

                implicitWidth: modeLabel.implicitWidth + 18
                implicitHeight: 22
                radius: Config.rounded ? 11 : 4
                color: mode.current ? Qt.alpha(Theme.glow, 0.22)
                    : modeHover.hovered ? Qt.alpha(Theme.glow, 0.1)
                    : "transparent"
                border.color: Qt.alpha(Theme.glow, 0.3)
                border.width: 1

                HoverHandler { id: modeHover }
                TapHandler { onTapped: root.write(behaviourFile, mode.modelData.id) }

                Text {
                    id: modeLabel
                    anchors.centerIn: parent
                    text: mode.modelData.label
                    color: mode.current ? Theme.fg : Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 11
                }
            }
        }
    }
}
