import Quickshell
import Quickshell.Bluetooth
import QtQuick
import qs.services

// Etat du bluetooth, reduit a un glyphe, comme Network.
//
// Sans bluetoothd en cours d'execution, l'interface D-Bus org.bluez
// n'existe pas : defaultAdapter reste null et le widget disparait plutot
// que d'afficher un etat invente.
Text {
    id: root

    property int size: 16

    // liaison declarative : comme Networking, le service ne se peuple
    // qu'une fois observe
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: root.adapter?.enabled ?? false
    readonly property var devices: root.adapter?.devices?.values ?? []
    readonly property var connectedDevices: root.devices.filter(d => d.connected)
    readonly property bool connected: root.connectedDevices.length > 0

    readonly property string details: {
        if (!root.adapter)
            return ""
        if (!root.enabled)
            return "Bluetooth off"
        if (!root.connected)
            return "Bluetooth on\nNo device connected"
        // le module expose le niveau de batterie des peripheriques, quand
        // ils le rapportent : c'est l'interet principal de l'infobulle
        return root.connectedDevices.map(d =>
            d.deviceName + (d.batteryAvailable ? " \u2014 " + Math.round(d.battery * 100) + " %" : "")
        ).join("\n")
    }

    visible: root.adapter !== null

    text: !root.enabled  ? "󰂲"
        : root.connected ? "󰂱"
        : "󰂯"

    font.family: Theme.font
    font.pixelSize: root.size * 1.25
    color: root.connected ? Theme.fg : (root.enabled ? Theme.muted : Theme.dim)

    Behavior on color { ColorAnimation { duration: 200 } }
}
