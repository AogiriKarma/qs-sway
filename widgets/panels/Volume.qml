import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import qs.services

// Mixer : un curseur par application qui joue du son, plus le choix de la
// sortie. PipeWire distingue les noeuds par leurs drapeaux — isStream pour
// un flux applicatif, isSink pour un peripherique de sortie.
ColumnLayout {
    id: root

    readonly property var nodes: Pipewire.nodes.values
    readonly property var streams: root.nodes.filter(n => n.isStream && n.audio && !n.isSink)
    readonly property var sinks: root.nodes.filter(n => n.isSink && !n.isStream)

    // Sans tracker, Quickshell ne synchronise pas les donnees de ces noeuds
    // et tous les volumes resteraient a zero. C'est le meme piege que pour
    // la sortie par defaut dans le widget de la barre.
    PwObjectTracker {
        objects: root.streams.concat(root.sinks)
    }

    function label(node) {
        return node.properties?.["application.name"]
            ?? node.nickname
            ?? node.description
            ?? node.name
    }

    spacing: 14

    // ---------- flux applicatifs
    Text {
        text: "Mixer"
        color: Theme.muted
        font.family: Theme.font
        font.pixelSize: 11
    }

    Text {
        visible: root.streams.length === 0
        text: "No application playing"
        color: Theme.dim
        font.family: Theme.font
        font.pixelSize: 12
    }

    Repeater {
        model: root.streams

        RowLayout {
            id: streamRow
            required property var modelData
            spacing: 10
            Layout.fillWidth: true

            Text {
                Layout.preferredWidth: 130
                text: root.label(streamRow.modelData)
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: 12
                elide: Text.ElideRight
            }

            Slider {
                Layout.fillWidth: true
                value: streamRow.modelData.audio?.volume ?? 0
                // on ecrit dans la source, jamais dans la valeur affichee :
                // assigner value detruirait le binding
                onMoved: v => streamRow.modelData.audio.volume = v
            }

            Text {
                Layout.preferredWidth: 34
                horizontalAlignment: Text.AlignRight
                text: Math.round((streamRow.modelData.audio?.volume ?? 0) * 100) + "%"
                color: Theme.muted
                font.family: Theme.fontMono
                font.pixelSize: 11
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Qt.alpha(Theme.glow, 0.2)
    }

    // ---------- choix de la sortie
    Text {
        text: "Output"
        color: Theme.muted
        font.family: Theme.font
        font.pixelSize: 11
    }

    Repeater {
        model: root.sinks

        Rectangle {
            id: sinkRow
            required property var modelData
            readonly property bool current: Pipewire.defaultAudioSink === sinkRow.modelData

            Layout.fillWidth: true
            implicitHeight: 26
            radius: Config.rounded ? 13 : 4
            color: sinkHover.hovered ? Qt.alpha(Theme.glow, 0.12) : "transparent"

            HoverHandler { id: sinkHover }
            TapHandler {
                // preferredDefaultAudioSink, et non defaultAudioSink :
                // on exprime une preference, wireplumber applique
                onTapped: Pipewire.preferredDefaultAudioSink = sinkRow.modelData
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                Text {
                    text: sinkRow.current ? "●" : "○"
                    color: sinkRow.current ? Theme.accent : Theme.dim
                    font.pixelSize: 10
                }

                Text {
                    Layout.fillWidth: true
                    text: root.label(sinkRow.modelData)
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }
        }
    }
}
