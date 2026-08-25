import QtQuick
import QtQuick.Layouts
import qs.services

// Liste deroulante qui se deplie EN PLACE plutot que dans une fenetre
// flottante : le panneau est deja une bulle qui s'anime, une fenetre de
// plus par-dessus ferait un troisieme niveau d'empilement pour rien.
ColumnLayout {
    id: root

    // [{ label: "...", value: <quoi que ce soit>, current: bool }, ...]
    property var options: []
    property string placeholder: "—"
    signal chose(var value)

    property bool open: false

    readonly property string currentLabel: {
        const found = root.options.find(o => o.current)
        return found ? found.label : root.placeholder
    }

    spacing: 2

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 28
        radius: Config.rounded ? 8 : 4
        color: headHover.hovered ? Qt.alpha(Theme.glow, 0.14) : Qt.alpha(Theme.glow, 0.08)
        border.color: Qt.alpha(Theme.glow, 0.3)
        border.width: 1

        HoverHandler { id: headHover }
        TapHandler { onTapped: root.open = !root.open }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10

            Text {
                Layout.fillWidth: true
                text: root.currentLabel
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: 12
                elide: Text.ElideRight
            }

            Text {
                // chevron qui pivote a l'ouverture
                text: "⌄"
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: 14
                rotation: root.open ? 180 : 0
                Behavior on rotation { NumberAnimation { duration: 140 } }
            }
        }
    }

    Repeater {
        model: root.open ? root.options : []

        Rectangle {
            id: option
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: 24
            radius: Config.rounded ? 8 : 4
            color: optionHover.hovered ? Qt.alpha(Theme.glow, 0.12) : "transparent"

            HoverHandler { id: optionHover }
            TapHandler {
                onTapped: {
                    root.chose(option.modelData.value)
                    root.open = false
                }
            }

            Text {
                anchors.fill: parent
                anchors.leftMargin: 18
                verticalAlignment: Text.AlignVCenter
                text: option.modelData.label
                color: option.modelData.current ? Theme.accent : Theme.fg
                font.family: Theme.font
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }
    }
}
