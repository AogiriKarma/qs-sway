import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import qs.services

ColumnLayout {
    id: root

    property int size: 16
    // taille de la ligne du bas, reglable independamment
    // pour l'aligner avec les autres widgets empiles
    property real labelSize: size * 0.75

    readonly property UPowerDevice device: UPower.displayDevice
    readonly property bool charging: device.state === UPowerDeviceState.Charging
    readonly property bool low: device.percentage <= 0.20 && !charging
    // seuil de charge du firmware : la batterie ne monte jamais au-dela
    readonly property bool full: device.percentage >= 0.80

    // glyphes nerd font md-battery, du plus vide au plus plein
    readonly property var levels: ["󰁺","󰁻","󰁼","󰁽","󰁾","󰁿","󰂀","󰂁","󰂂","󰁹"]
    readonly property string icon: charging ? "󰂄"
        : levels[Math.min(9, Math.floor(device.percentage * 10))]

    // secondes -> "2 h 05" ou "45 min" ; "" si UPower ne sait pas encore
    function formatDuration(seconds) {
        if (!seconds || seconds <= 0)
            return ""
        const h = Math.floor(seconds / 3600)
        const m = Math.round((seconds % 3600) / 60)
        return h > 0 ? h + " h " + String(m).padStart(2, "0") : m + " min"
    }

    readonly property string details: {
        const pct = Math.round(root.device.percentage * 100) + " %"
        const state = root.charging ? "charging" : (root.full ? "charged" : "on battery")
        // UPower ne renseigne le temps restant qu'une fois le debit stabilise
        const left = root.formatDuration(root.charging ? root.device.timeToFull : root.device.timeToEmpty)
        const suffix = left ? "\n" + (root.charging ? "Full in " : "Remaining ") + left : ""
        return "Battery " + pct + " \u2014 " + state + suffix
    }

    readonly property color tint: charging ? Theme.special
        : low  ? Theme.danger
        : full ? Theme.glow
        : Theme.fg

    visible: device.isLaptopBattery
    spacing: -root.size * 0.25

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: root.icon
        font.family: Theme.font
        font.pixelSize: root.size * 1.25
        color: root.tint

        Behavior on color { ColorAnimation { duration: 200 } }
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: Math.round(root.device.percentage * 100) + "%"
        font.family: Theme.font
        font.pixelSize: root.labelSize
        color: root.low ? Theme.danger : Theme.fg
    }
}
