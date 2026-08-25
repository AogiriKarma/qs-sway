import Quickshell
import Quickshell.Bluetooth
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.services

// Page bluetooth, d'apres le schema. Deux ecrans : la liste, et le detail
// d'un appareil. Le detail remplace la liste au lieu de s'ouvrir a cote —
// la bulle est deja etroite, et un second niveau flottant serait de trop.
ColumnLayout {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var devices: root.adapter?.devices?.values ?? []
    readonly property var known: root.devices.filter(d => d.paired || d.bonded)
    readonly property var available: root.devices.filter(d => !d.paired && !d.bonded)

    // appareil dont on regarde le detail ; null = on est sur la liste
    property var detail: null

    // Le scan demarre a l'ouverture du panneau et s'arrete a sa fermeture :
    // une decouverte laissee active consomme et sature les journaux.
    Component.onCompleted: if (root.adapter?.enabled) root.adapter.discovering = true
    Component.onDestruction: if (root.adapter) root.adapter.discovering = false

    spacing: 10

    // ================= ecran de detail
    ColumnLayout {
        visible: root.detail !== null
        Layout.fillWidth: true
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "‹"
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 18
            }

            Text {
                Layout.fillWidth: true
                text: "return"
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 12
            }

            HoverHandler { cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: root.detail = null }
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 68
            implicitHeight: 68
            radius: Config.rounded ? width / 2 : 8
            color: "transparent"
            border.color: Qt.alpha(Theme.glow, 0.4)
            border.width: 1

            IconImage {
                anchors.centerIn: parent
                implicitSize: 34
                visible: source !== ""
                source: root.detail?.icon ? Quickshell.iconPath(root.detail.icon, true) : ""
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.detail?.deviceName ?? ""
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: 13
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            visible: root.detail?.batteryAvailable ?? false
            text: Math.round((root.detail?.battery ?? 0) * 100) + "% battery"
            color: Theme.muted
            font.family: Theme.fontMono
            font.pixelSize: 11
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 16

            // oublier : petit, a gauche, comme sur le schema
            Rectangle {
                implicitWidth: 34
                implicitHeight: 34
                radius: Config.rounded ? width / 2 : 6
                color: forgetHover.hovered ? Qt.alpha(Theme.danger, 0.25) : "transparent"
                border.color: Qt.alpha(Theme.glow, 0.3)
                border.width: 1

                HoverHandler { id: forgetHover; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    onTapped: {
                        root.detail.forget()
                        root.detail = null
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰅖"
                    color: forgetHover.hovered ? Theme.danger : Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 15
                }
            }

            Item { Layout.fillWidth: true }

            // connecter / deconnecter : plus gros, a droite
            Rectangle {
                implicitWidth: 46
                implicitHeight: 46
                radius: Config.rounded ? width / 2 : 8
                color: root.detail?.connected ? Qt.alpha(Theme.glow, 0.22)
                    : connectHover.hovered ? Qt.alpha(Theme.glow, 0.12)
                    : "transparent"
                border.color: root.detail?.connected ? Theme.accent : Qt.alpha(Theme.glow, 0.3)
                border.width: root.detail?.connected ? 2 : 1

                HoverHandler { id: connectHover; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    onTapped: {
                        if (root.detail.connected)
                            root.detail.disconnect()
                        else
                            root.detail.connect()
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: root.detail?.connected ? "󰂱" : "󰂯"
                    color: root.detail?.connected ? Theme.fg : Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 20
                }
            }
        }
    }

    // ================= ecran de liste
    ColumnLayout {
        visible: root.detail === null
        Layout.fillWidth: true
        spacing: 8

        // ---------- en-tete : bascule On / Off
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                Layout.fillWidth: true
                text: "Bluetooth"
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: 13
            }

            Row {
                spacing: 0

                Repeater {
                    model: [{ label: "On", value: true }, { label: "Off", value: false }]

                    Rectangle {
                        id: seg
                        required property var modelData
                        required property int index
                        readonly property bool current: (root.adapter?.enabled ?? false) === seg.modelData.value

                        implicitWidth: 38
                        implicitHeight: 24
                        color: seg.current ? Qt.alpha(Theme.glow, 0.22)
                            : segHover.hovered ? Qt.alpha(Theme.glow, 0.1)
                            : "transparent"
                        border.color: Qt.alpha(Theme.glow, 0.3)
                        border.width: 1
                        // coins arrondis seulement aux extremites du groupe
                        topLeftRadius: seg.index === 0 && Config.rounded ? 12 : 0
                        bottomLeftRadius: seg.index === 0 && Config.rounded ? 12 : 0
                        topRightRadius: seg.index === 1 && Config.rounded ? 12 : 0
                        bottomRightRadius: seg.index === 1 && Config.rounded ? 12 : 0

                        HoverHandler { id: segHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: {
                                if (root.adapter)
                                    root.adapter.enabled = seg.modelData.value
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: seg.modelData.label
                            color: seg.current ? Theme.fg : Theme.muted
                            font.family: Theme.font
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }

        // ---------- listes, defilantes
        Scroller {
            Layout.fillWidth: true
            maxHeight: 220

            ColumnLayout {
                width: parent.width
                spacing: 6

                Repeater {
                    model: [
                        { title: "Known", items: root.known },
                        { title: "Available", items: root.available }
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

                        Text {
                            visible: section.modelData.items.length === 0
                            text: section.modelData.title === "Known" ? "nothing paired" : "scanning..."
                            color: Theme.dim
                            font.family: Theme.font
                            font.pixelSize: 11
                        }

                        Repeater {
                            model: section.modelData.items

                            Rectangle {
                                id: deviceRow
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 28
                                radius: Config.rounded ? 8 : 4
                                color: deviceHover.hovered ? Qt.alpha(Theme.glow, 0.12) : "transparent"

                                HoverHandler { id: deviceHover; cursorShape: Qt.PointingHandCursor }
                                TapHandler {
                                    // un appareil connu se (de)connecte au clic,
                                    // un appareil decouvert s'appaire
                                    onTapped: {
                                        const d = deviceRow.modelData
                                        if (d.connected)
                                            d.disconnect()
                                        else if (d.paired || d.bonded)
                                            d.connect()
                                        else
                                            d.pair()
                                    }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 6
                                    spacing: 8

                                    IconImage {
                                        implicitSize: 16
                                        visible: source !== ""
                                        source: deviceRow.modelData.icon
                                            ? Quickshell.iconPath(deviceRow.modelData.icon, true)
                                            : ""
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: deviceRow.modelData.deviceName || deviceRow.modelData.address
                                        color: deviceRow.modelData.connected ? Theme.accent : Theme.fg
                                        font.family: Theme.font
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        visible: deviceRow.modelData.batteryAvailable
                                        text: Math.round(deviceRow.modelData.battery * 100) + "%"
                                        color: Theme.muted
                                        font.family: Theme.fontMono
                                        font.pixelSize: 10
                                    }

                                    // l'engrenage ouvre le detail, sans
                                    // declencher la connexion de la ligne
                                    Text {
                                        text: "󰒓"
                                        color: gearHover.hovered ? Theme.accent : Theme.muted
                                        font.family: Theme.font
                                        font.pixelSize: 14

                                        HoverHandler { id: gearHover; cursorShape: Qt.PointingHandCursor }
                                        TapHandler { onTapped: root.detail = deviceRow.modelData }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
