import Quickshell
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts
import qs.services

// Page reseau, d'apres le schema : deux onglets, l'ethernet en fiche
// d'etat, le wifi en liste. Chacun se termine par le choix de l'interface.
ColumnLayout {
    id: root

    // 0 = ethernet, 1 = wifi. On ouvre sur l'onglet qui porte le trafic.
    property int tab: (root.wired?.connected ?? false) ? 0 : 1
    property var detail: null

    readonly property var devices: Networking.devices.values
    readonly property var wiredDevices: root.devices.filter(d => d.type === DeviceType.Wired)
    readonly property var wifiDevices: root.devices.filter(d => d.type === DeviceType.Wifi)
    readonly property var wired: root.wiredDevices.find(d => d.connected) ?? root.wiredDevices[0] ?? null
    readonly property var wifi: root.wifiDevices.find(d => d.connected) ?? root.wifiDevices[0] ?? null

    readonly property var networks: (root.wifi?.networks?.values ?? []).slice().sort((a, b) => {
        if (a.connected !== b.connected)
            return a.connected ? -1 : 1
        return b.signalStrength - a.signalStrength
    })
    readonly property var knownNetworks: root.networks.filter(n => n.known)
    readonly property var otherNetworks: root.networks.filter(n => !n.known)

    // le scan tourne tant que la page est ouverte, pas au-dela
    Component.onCompleted: if (root.wifi) root.wifi.scannerEnabled = true
    Component.onDestruction: if (root.wifi) root.wifi.scannerEnabled = false

    function humanRate(bytesPerSec) {
        if (bytesPerSec < 1000)
            return Math.round(bytesPerSec) + ""
        if (bytesPerSec < 1000000)
            return Math.round(bytesPerSec / 1000) + "k"
        return (bytesPerSec / 1000000).toFixed(1) + "M"
    }

    spacing: 10

    // ---------- onglets
    RowLayout {
        Layout.fillWidth: true
        spacing: 4

        Repeater {
            model: ["Ethernet", "Wi-Fi"]

            ColumnLayout {
                id: tabItem
                required property int index
                required property string modelData
                readonly property bool current: root.tab === tabItem.index
                Layout.fillWidth: true
                spacing: 4

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: tabItem.modelData
                    color: tabItem.current ? Theme.fg : Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 12
                }

                // le soulignement porte l'etat actif, comme sur le schema
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 2
                    color: tabItem.current ? Theme.accent : Qt.alpha(Theme.glow, 0.2)

                    Behavior on color { ColorAnimation { duration: 140 } }
                }

                HoverHandler { cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: root.tab = tabItem.index }
            }
        }
    }

    // ================= onglet ethernet
    ColumnLayout {
        visible: root.tab === 0
        Layout.fillWidth: true
        spacing: 8

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 52
            implicitHeight: 52
            radius: Config.rounded ? width / 2 : 8
            color: "transparent"
            border.color: Qt.alpha(Theme.glow, root.wired?.connected ? 0.5 : 0.25)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "󰈀"
                color: root.wired?.connected ? Theme.fg : Theme.dim
                font.family: Theme.font
                font.pixelSize: 22
            }
        }

        Repeater {
            model: [
                { key: "State", value: root.wired ? (root.wired.connected ? "Connected" : "Disconnected") : "No interface" },
                { key: "Link speed", value: (root.wired?.linkSpeed ?? 0) > 0 ? root.wired.linkSpeed + " Mb/s" : "—" },
                { key: "up/down", value: root.humanRate(SysStats.txRate) + " / " + root.humanRate(SysStats.rxRate) }
            ]

            RowLayout {
                id: infoLine
                required property var modelData
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: infoLine.modelData.key
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 11
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: infoLine.modelData.value
                    color: Theme.fg
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                }
            }
        }

        Dropdown {
            Layout.fillWidth: true
            Layout.topMargin: 4
            placeholder: "No wired interface"
            options: root.wiredDevices.map(d => ({
                label: d.name + (d.hasLink ? " — plugged" : ""),
                value: d,
                current: d === root.wired
            }))
            // informatif : NetworkManager choisit lui-meme l'interface active
            onChose: value => {}
        }
    }

    // ================= onglet wifi
    ColumnLayout {
        visible: root.tab === 1
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: Networking.wifiEnabled
                    ? root.networks.length + " networks"
                    : "Wi-Fi is off"
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 11
            }

            PanelButton {
                text: Networking.wifiEnabled ? "Off" : "On"
                onActivated: Networking.wifiEnabled = !Networking.wifiEnabled
            }
        }

        Scroller {
            Layout.fillWidth: true
            maxHeight: 220

            ColumnLayout {
                width: parent.width
                spacing: 6

                Repeater {
                    model: [
                        { title: "Known", items: root.knownNetworks },
                        { title: "Available", items: root.otherNetworks }
                    ]

                    ColumnLayout {
                        id: section
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: section.modelData.title
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: 11
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 1
                            color: Qt.alpha(Theme.glow, 0.2)
                        }

                        Repeater {
                            model: section.modelData.items

                            Rectangle {
                                id: netRow
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 28
                                radius: Config.rounded ? 8 : 4
                                color: netHover.hovered ? Qt.alpha(Theme.glow, 0.12) : "transparent"

                                HoverHandler { id: netHover; cursorShape: Qt.PointingHandCursor }
                                TapHandler {
                                    onTapped: {
                                        const n = netRow.modelData
                                        if (n.connected)
                                            n.disconnect()
                                        else if (n.known || n.security === WifiSecurityType.Open)
                                            n.connect()
                                        else
                                            root.detail = n
                                    }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 6
                                    spacing: 8

                                    Text {
                                        text: "󰤨"
                                        color: netRow.modelData.connected ? Theme.accent : Theme.muted
                                        font.family: Theme.font
                                        font.pixelSize: 13
                                        opacity: 0.4 + 0.6 * netRow.modelData.signalStrength
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: netRow.modelData.name
                                        color: netRow.modelData.connected ? Theme.accent : Theme.fg
                                        font.family: Theme.font
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: "󰒓"
                                        color: gearHover.hovered ? Theme.accent : Theme.muted
                                        font.family: Theme.font
                                        font.pixelSize: 14

                                        HoverHandler { id: gearHover; cursorShape: Qt.PointingHandCursor }
                                        TapHandler { onTapped: root.detail = netRow.modelData }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // saisie du mot de passe : la fenetre ne prend le clavier que
        // panneau ouvert, le champ peut donc reclamer le focus
        ColumnLayout {
            visible: root.detail !== null
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: root.detail?.name ?? ""
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: 12
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 24
                    radius: Config.rounded ? 8 : 4
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
                        focus: root.detail !== null
                        onAccepted: {
                            root.detail.connectWithPsk(text)
                            root.detail = null
                        }
                    }
                }

                PanelButton {
                    text: "Connect"
                    onActivated: {
                        root.detail.connectWithPsk(pskField.text)
                        root.detail = null
                    }
                }
            }
        }

        Dropdown {
            Layout.fillWidth: true
            placeholder: "No adapter"
            options: root.wifiDevices.map(d => ({
                label: d.name,
                value: d,
                current: d === root.wifi
            }))
            onChose: value => {}
        }
    }
}
