import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.services

// Page son, d'apres le schema : un curseur par application avec son icone
// a droite, la sortie en liste deroulante, puis le volume general.
ColumnLayout {
    id: root

    readonly property var nodes: Pipewire.nodes.values
    // PIEGE : isSink vaut true pour un flux d'application aussi — il signifie
    // "alimente une sortie", pas "est un peripherique". C'est isStream qui
    // separe les deux.
    readonly property var streams: root.nodes.filter(n => n.isStream && n.isSink && n.audio)
    readonly property var sinks: root.nodes.filter(n => !n.isStream && n.isSink && n.audio)
    readonly property var sink: Pipewire.defaultAudioSink

    // Sans tracker, Quickshell ne synchronise pas ces noeuds et tous les
    // volumes resteraient a zero.
    PwObjectTracker {
        objects: root.streams.concat(root.sinks).concat(root.sink ? [root.sink] : [])
    }

    // "PipeWire ALSA [myx]" -> "myx" : les applications qui passent par la
    // couche de compatibilite ALSA de PipeWire s'annoncent sous ce nom, le
    // vrai etant entre crochets.
    function appName(node) {
        const raw = node?.properties?.["application.name"] ?? ""
        const bracketed = /\[([^\]]+)\]/.exec(raw)
        if (bracketed)
            return bracketed[1]
        return raw || node?.properties?.["application.process.binary"] || ""
    }

    function label(node) {
        return root.appName(node) || node?.nickname || node?.description || node?.name || ""
    }

    // l'icone de l'appli : PipeWire la donne parfois directement, sinon on
    // la deduit du nom via les entrees desktop, comme pour les workspaces
    function iconOf(node) {
        const direct = node?.properties?.["application.icon-name"]
        if (direct) {
            const p = Quickshell.iconPath(direct, true)
            if (p)
                return p
        }
        const entries = DesktopEntries.applications.values
        // on cherche sur le nom nettoye : "PipeWire ALSA [myx]" ne
        // correspondrait a aucune entree desktop, "myx" peut-etre
        const name = root.appName(node)
        const icon = name ? (entries, DesktopEntries.heuristicLookup(name)?.icon ?? "") : ""
        return icon ? Quickshell.iconPath(icon, true) : ""
    }

    spacing: 10

    // ---------- un curseur par application
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
            Layout.fillWidth: true
            spacing: 10

            Slider {
                Layout.fillWidth: true
                Layout.preferredWidth: 150
                value: streamRow.modelData.audio?.volume ?? 0
                // on ecrit dans la source, jamais dans la valeur affichee
                onMoved: v => streamRow.modelData.audio.volume = v
            }

            Text {
                Layout.preferredWidth: 26
                horizontalAlignment: Text.AlignRight
                text: Math.round((streamRow.modelData.audio?.volume ?? 0) * 100)
                color: Theme.muted
                font.family: Theme.fontMono
                font.pixelSize: 11
            }

            // l'icone de l'appli, ou un glyphe neutre : un programme lance
            // au terminal n'a pas d'entree desktop, et une case vide
            // desalignerait la ligne
            Item {
                implicitWidth: 20
                implicitHeight: 20

                IconImage {
                    id: streamIcon
                    anchors.fill: parent
                    source: root.iconOf(streamRow.modelData)
                    visible: source !== ""
                }

                Text {
                    anchors.centerIn: parent
                    visible: !streamIcon.visible
                    text: "󰕾"
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 15
                }
            }
        }
    }

    // ---------- sortie
    Dropdown {
        Layout.fillWidth: true
        Layout.topMargin: 4
        placeholder: "No output"
        options: root.sinks.map(s => ({
            label: root.label(s),
            value: s,
            current: s === root.sink
        }))
        // preferredDefaultAudioSink, et non defaultAudioSink : on exprime
        // une preference, wireplumber applique
        onChose: value => Pipewire.preferredDefaultAudioSink = value
    }

    // ---------- volume general
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Slider {
            Layout.fillWidth: true
            Layout.preferredWidth: 150
            value: root.sink?.audio?.volume ?? 0
            onMoved: v => { if (root.sink?.audio) root.sink.audio.volume = v }
        }

        Text {
            Layout.preferredWidth: 26
            horizontalAlignment: Text.AlignRight
            text: Math.round((root.sink?.audio?.volume ?? 0) * 100)
            color: Theme.muted
            font.family: Theme.fontMono
            font.pixelSize: 11
        }

        // glyphes nerd font : haut-parleur, ou barre quand c'est coupe
        Text {
            // caracteres litteraux : un echappement \u ne lit que quatre
            // chiffres hexadecimaux, et "\uf075f" donnerait \uf075 suivi
            // d'un "f" — soit un glyphe faux et une lettre parasite
            text: root.sink?.audio?.muted ? "󰝟" : "󰕾"
            color: root.sink?.audio?.muted ? Theme.dim : Theme.fg
            font.family: Theme.font
            font.pixelSize: 18

            HoverHandler { cursorShape: Qt.PointingHandCursor }
            TapHandler {
                onTapped: {
                    if (root.sink?.audio)
                        root.sink.audio.muted = !root.sink.audio.muted
                }
            }
        }
    }
}
