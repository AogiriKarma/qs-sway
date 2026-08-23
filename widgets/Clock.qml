import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services

ColumnLayout {
    id: root

    property int size: 25
    // taille de la ligne du bas, reglable independamment
    // pour l'aligner avec les autres widgets empiles
    property real labelSize: size * 0.75

    spacing: -3

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: Qt.locale().toString(clock.date, "HH:mm")
        color: Theme.fg
        font.family: Theme.fontMono
        font.pixelSize: root.size
        font.bold: true
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: Qt.locale().toString(clock.date, "dd/MM")
        color: Theme.fg
        font.family: Theme.fontMono
        font.pixelSize: root.labelSize
    }
}