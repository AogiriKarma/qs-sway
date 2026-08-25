import Quickshell
import Quickshell.Bluetooth
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.services

// Liste des appareils, groupes par etat : connectes d'abord, puis connus,
// puis ceux que la decouverte fait apparaitre. Cliquer un appareil deplie
// ses actions plutot que d'ouvrir un menu flottant de plus.
ColumnLayout {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var devices: root.adapter?.devices?.values ?? []

    // un appareil "connu" est appaire : on peut s'y reconnecter sans refaire
    // l'appairage. Les autres viennent de la decouverte en cours.
    readonly property var connected: root.devices.filter(d => d.connected)
    readonly property var known: root.devices.filter(d => !d.connected && (d.paired || d.bonded))
    readonly property var discovered: root.devices.filter(d => !d.connected && !d.paired && !d.bonded)

    property var selected: null

    spacing: 10

    // ---------- en-tete : radio et decouverte
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Text {
            Layout.fillWidth: true
            text: root.adapter ? (root.adapter.enabled ? "Bluetooth on" : "Bluetooth off") : "No adapter"
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: 13
            font.bold: true
        }

        PanelButton {
            text: root.adapter?.enabled ? "Turn off" : "Turn on"
            enabled: root.adapter !== null
            onActivated: root.adapter.enabled = !root.adapter.enabled
        }

        PanelButton {
            text: root.adapter?.discovering ? "Stop scan" : "Scan"
            enabled: root.adapter?.enabled ?? false
            onActivated: root.adapter.discovering = !root.adapter.discovering
        }
    }

    Repeater {
        model: [
            { title: "Connected", items: root.connected },
            { title: "Known", items: root.known },
            { title: "Available", items: root.discovered }
        ]

        ColumnLayout {
            id: group
            required property var modelData
            visible: group.modelData.items.length > 0
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: group.modelData.title
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 11
            }

            Repeater {
                model: group.modelData.items

                ColumnLayout {
                    id: row
                    required property var modelData
                    readonly property bool open: root.selected === row.modelData
                    Layout.fillWidth: true
                    spacing: 4

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 28
                        radius: Config.rounded ? 14 : 4
                        color: rowHover.hovered || row.open ? Qt.alpha(Theme.glow, 0.12) : "transparent"

                        HoverHandler { id: rowHover }
                        TapHandler {
                            onTapped: root.selected = row.open ? null : row.modelData
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            IconImage {
                                implicitSize: 16
                                visible: source !== ""
                                source: row.modelData.icon ? Quickshell.iconPath(row.modelData.icon, true) : ""
                            }

                            Text {
                                Layout.fillWidth: true
                                text: row.modelData.deviceName || row.modelData.address
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }

                            // le niveau de batterie n'est rapporte que par
                            // certains peripheriques, casques en tete
                            Text {
                                visible: row.modelData.batteryAvailable
                                text: Math.round(row.modelData.battery * 100) + "%"
                                color: Theme.muted
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                            }
                        }
                    }

                    // actions depliees sous l'appareil selectionne
                    RowLayout {
                        visible: row.open
                        Layout.fillWidth: true
                        Layout.leftMargin: 12
                        spacing: 6

                        PanelButton {
                            text: row.modelData.connected ? "Disconnect" : "Connect"
                            onActivated: row.modelData.connected
                                ? row.modelData.disconnect()
                                : row.modelData.connect()
                        }

                        PanelButton {
                            visible: !row.modelData.paired && !row.modelData.bonded
                            text: "Pair"
                            onActivated: row.modelData.pair()
                        }

                        PanelButton {
                            visible: row.modelData.paired || row.modelData.bonded
                            text: "Forget"
                            onActivated: {
                                row.modelData.forget()
                                root.selected = null
                            }
                        }

                        PanelButton {
                            text: row.modelData.trusted ? "Untrust" : "Trust"
                            onActivated: row.modelData.trusted = !row.modelData.trusted
                        }
                    }
                }
            }
        }
    }

    Text {
        visible: root.adapter !== null && root.devices.length === 0
        text: "No device — start a scan"
        color: Theme.dim
        font.family: Theme.font
        font.pixelSize: 12
    }
}
