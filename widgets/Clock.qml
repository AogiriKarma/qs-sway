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

    // suit la locale systeme, comme le reste des infobulles
    readonly property string details: Qt.locale().toString(clock.date, "dddd d MMMM yyyy")

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // "00:49" fait environ 50 px de large : dans une barre laterale les
    // minutes passent sous les heures, sinon l'horloge deborde de la bulle
    Text {
        Layout.alignment: Qt.AlignHCenter
        text: Qt.locale().toString(clock.date, Config.vertical ? "HH" : "HH:mm")
        color: Theme.fg
        font.family: Theme.fontMono
        font.pixelSize: root.size
        font.bold: true
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        visible: Config.vertical
        text: Qt.locale().toString(clock.date, "mm")
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