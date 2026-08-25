import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import qs.services

Item {
    id: root

    property int size: 16
    // taille de la ligne du bas, reglable independamment
    // pour l'aligner avec les autres widgets empiles
    property real labelSize: size * 0.75
    // pas de molette, et plafond : PipeWire autorise la surampli (> 1.0),
    // on se limite a 100% tant qu'on n'a pas decide du contraire
    property real step: 0.05
    property real maxVolume: 1.0

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNodeAudio audio: sink?.audio ?? null

    readonly property real volume: audio?.volume ?? 0
    readonly property bool muted: audio?.muted ?? false

    // glyphes nerd font md-volume, du plus bas au plus haut
    readonly property var levels: ["󰕿", "󰖀", "󰕾"]
    readonly property string icon: muted
        ? "󰖁"
        : levels[Math.min(2, Math.floor(volume * 3))]

    readonly property color tint: muted ? Theme.dim : Theme.fg

    // sans sink (aucune sortie audio), le widget disparait entierement
    visible: audio !== null
    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight

    // Quickshell ne synchronise les donnees d'un objet PipeWire que s'il est
    // traque explicitement — sans ca, volume/muted restent figes a zero
    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    ColumnLayout {
        id: col
        anchors.centerIn: parent
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
            text: Math.round(root.volume * 100) + "%"
            font.family: Theme.font
            font.pixelSize: root.labelSize
            color: root.tint
        }
    }

    MouseArea {
        anchors.fill: parent
        // Le clic gauche appartient desormais au panneau : c'est lui qui
        // ouvre le mixer. Le mute passe au bouton du milieu, la molette
        // continue de regler le volume.
        acceptedButtons: Qt.MiddleButton
        onClicked: if (root.audio) root.audio.muted = !root.audio.muted

        onWheel: event => {
            if (!root.audio)
                return
            root.audio.muted = false
            const delta = event.angleDelta.y > 0 ? root.step : -root.step
            root.audio.volume = Math.max(0, Math.min(root.maxVolume, root.volume + delta))
        }
    }
}
