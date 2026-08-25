import Quickshell
import Quickshell.Networking
import QtQuick
import qs.services

// Etat du lien reseau, reduit a un glyphe : le debit est une statistique
// systeme, il vit dans SysStats et s'affiche dans la bulle des stats.
Text {
    id: root

    property int size: 16

    // Networking est un service paresseux : il ne peuple ses listes qu'une
    // fois qu'une liaison declarative les observe. Ce binding l'amorce —
    // une simple lecture en JavaScript ne le reveillerait pas.
    readonly property var devices: Networking.devices.values
    readonly property var wifiDevice: root.devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wiredDevice: root.devices.find(d => d.type === DeviceType.Wired) ?? null

    // le filaire prime quand il est branche : c'est lui qui porte le trafic
    readonly property bool onWired: root.wiredDevice?.connected ?? false
    readonly property var wifiNetwork: root.wifiDevice?.networks?.values?.find(n => n.connected) ?? null
    // PIEGE : signalStrength est en 0-1, comme percentage d'UPower
    readonly property real strength: root.wifiNetwork?.signalStrength ?? 0
    readonly property bool connected: root.onWired || (root.wifiNetwork !== null)

    // glyphes nerd font md-wifi, du plus faible au plus fort
    readonly property var levels: ["󰤟", "󰤢", "󰤥", "󰤨"]

    // aucune interface reseau du tout (VM, conteneur) : le widget disparait
    visible: root.devices.length > 0

    text: root.onWired
        ? "󰈀"
        : !Networking.wifiEnabled ? "󰤭"
        : !root.wifiNetwork       ? "󰤯"
        : root.levels[Math.min(3, Math.floor(root.strength * 4))]

    font.family: Theme.font
    font.pixelSize: root.size * 1.25
    color: root.connected ? Theme.fg : Theme.dim

    Behavior on color { ColorAnimation { duration: 200 } }
}
