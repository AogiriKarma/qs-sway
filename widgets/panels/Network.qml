import Quickshell
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts
import qs.services

// Deux onglets, parce que filaire et sans fil ne repondent pas aux memes
// questions : l'ethernet se resume a "est-ce branche et a quelle vitesse",
// le wifi demande une liste et un choix.
ColumnLayout {
    id: root

    property int tab: 1
    property var selected: null
    property string psk: ""

    readonly property var devices: Networking.devices.values
    readonly property var wired: root.devices.find(d => d.type === DeviceType.Wired) ?? null
    readonly property var wifi: root.devices.find(d => d.type === DeviceType.Wifi) ?? null

    // connecte en premier, puis les reseaux connus, puis par force de signal
    readonly property var networks: (root.wifi?.networks?.values ?? []).slice().sort((a, b) => {
        if (a.connected !== b.connected)
            return a.connected ? -1 : 1
        if (a.known !== b.known)
            return a.known ? -1 : 1
        return b.signalStrength - a.signalStrength
    })

    function connectTo(network) {
        // un reseau connu ou ouvert n'a pas besoin de mot de passe
        if (network.known || network.security === WifiSecurityType.Open) {
            network.connect()
            root.selected = null
            return
        }
        root.selected = network
        root.psk = ""
    }

    spacing: 10

    // ---------- onglets
    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Repeater {
            model: ["Ethernet", "Wi-Fi"]

            Rectangle {
                id: tabButton
                required property int index
                required property string modelData
                readonly property bool current: root.tab === tabButton.index

                Layout.fillWidth: true
                implicitHeight: 24
                radius: Config.rounded ? 12 : 4
                color: tabButton.current ? Qt.alpha(Theme.glow, 0.18)
                    : tabHover.hovered ? Qt.alpha(Theme.glow, 0.08)
                    : "transparent"

                HoverHandler { id: tabHover }
                TapHandler { onTapped: root.tab = tabButton.index }

                Text {
                    anchors.centerIn: parent
                    text: tabButton.modelData
                    color: tabButton.current ? Theme.fg : Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 12
                }
            }
        }
    }

    // ---------- onglet filaire
    ColumnLayout {
        visible: root.tab === 0
        Layout.fillWidth: true
        spacing: 4

        Text {
            visible: !root.wired
            text: "No wired interface"
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: 12
        }

        Repeater {
            model: root.wired ? [
                { key: "Interface", value: root.wired.name },
                { key: "Link", value: root.wired.hasLink ? "plugged" : "unplugged" },
                { key: "State", value: root.wired.connected ? "connected" : "disconnected" },
                { key: "Speed", value: root.wired.linkSpeed > 0 ? root.wired.linkSpeed + " Mb/s" : "—" },
                { key: "Address", value: root.wired.address || "—" }
            ] : []

            RowLayout {
                id: line
                required property var modelData
                Layout.fillWidth: true
                spacing: 10

                Text {
                    Layout.preferredWidth: 70
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
    }

    // ---------- onglet sans fil
    ColumnLayout {
        visible: root.tab === 1
        Layout.fillWidth: true
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: Networking.wifiEnabled ? root.networks.length + " networks" : "Wi-Fi is off"
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 11
            }

            PanelButton {
                text: Networking.wifiEnabled ? "Turn off" : "Turn on"
                onActivated: Networking.wifiEnabled = !Networking.wifiEnabled
            }
        }

        Repeater {
            model: root.networks.slice(0, 8)

            ColumnLayout {
                id: netRow
                required property var modelData
                readonly property bool asking: root.selected === netRow.modelData
                Layout.fillWidth: true
                spacing: 4

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 26
                    radius: Config.rounded ? 13 : 4
                    color: netHover.hovered || netRow.asking ? Qt.alpha(Theme.glow, 0.12) : "transparent"

                    HoverHandler { id: netHover }
                    TapHandler {
                        onTapped: netRow.modelData.connected
                            ? netRow.modelData.disconnect()
                            : root.connectTo(netRow.modelData)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        Text {
                            text: netRow.modelData.connected ? "●" : (netRow.modelData.known ? "○" : " ")
                            color: netRow.modelData.connected ? Theme.accent : Theme.dim
                            font.pixelSize: 10
                        }

                        Text {
                            Layout.fillWidth: true
                            text: netRow.modelData.name
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }

                        Text {
                            // signalStrength est en 0-1, comme ailleurs
                            text: Math.round(netRow.modelData.signalStrength * 100) + "%"
                            color: Theme.muted
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                        }
                    }
                }

                // saisie du mot de passe, seulement pour un reseau inconnu
                RowLayout {
                    visible: netRow.asking
                    Layout.fillWidth: true
                    Layout.leftMargin: 12
                    spacing: 6

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 22
                        radius: Config.rounded ? 11 : 4
                        color: Qt.alpha(Theme.glow, 0.1)
                        border.color: Qt.alpha(Theme.glow, 0.3)
                        border.width: 1

                        TextInput {
                            id: pskField
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: TextInput.Password
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: 11
                            // la fenetre ne prend le clavier que panneau
                            // ouvert : le focus peut donc etre demande ici
                            focus: netRow.asking
                            onTextChanged: root.psk = text
                            onAccepted: netRow.modelData.connectWithPsk(root.psk)
                        }
                    }

                    PanelButton {
                        text: "Connect"
                        onActivated: netRow.modelData.connectWithPsk(root.psk)
                    }
                }
            }
        }
    }
}
