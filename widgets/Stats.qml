import QtQuick
import QtQuick.Layouts
import qs.services

// Statistiques systeme. Chaque entree occupe deux lignes : soit un glyphe
// au-dessus de sa valeur, comme Volume et Battery, soit deux valeurs pour
// le reseau, dont les deux sens n'auraient aucun sens separes.
//
// La liste et l'ordre viennent de Config.stats — le widget ne decide pas
// de ce qui merite d'etre montre.
Grid {
    id: root

    property int size: 16
    property real labelSize: size * 0.75

    columns: Config.vertical ? 1 : root.entries.length
    // meme respiration qu'entre les widgets de la bulle systeme
    spacing: 14
    // Le bloc reseau fait deux petites lignes la ou les autres ont un gros
    // glyphe : sans alignement explicite, Grid les cale par le haut et le
    // reseau flotte au-dessus des pourcentages.
    horizontalItemAlignment: Grid.AlignHCenter
    verticalItemAlignment: Grid.AlignVCenter

    // 1,2M / 340k / 12 — une decimale sous 10 pour que la largeur du texte
    // ne saute pas a chaque echantillon
    function humanize(bytesPerSec) {
        if (bytesPerSec < 1000)
            return Math.round(bytesPerSec) + ""
        if (bytesPerSec < 1000000) {
            const k = bytesPerSec / 1000
            return (k < 10 ? k.toFixed(1) : Math.round(k)) + "k"
        }
        const m = bytesPerSec / 1000000
        return (m < 10 ? m.toFixed(1) : Math.round(m)) + "M"
    }

    // 4.2 GB — pour les tailles, pas pour les debits
    function humanBytes(bytes) {
        const g = bytes / 1073741824
        if (g >= 1)
            return (g < 10 ? g.toFixed(1) : Math.round(g)) + " GB"
        return Math.round(bytes / 1048576) + " MB"
    }

    function percent(ratio) {
        return Math.round(ratio * 100) + "%"
    }

    // glyph: true -> la ligne du haut est un glyphe, donc en grand
    readonly property var definitions: ({
        "cpu":  { top: "󰍛",  bottom: root.percent(SysStats.cpuUsage), glyph: true,
                  tip: "CPU " + root.percent(SysStats.cpuUsage) },
        "temp": { top: "󰔏", bottom: Math.round(SysStats.cpuTemp) + "\u00b0", glyph: true,
                  tip: "CPU temperature\n" + SysStats.cpuTemp.toFixed(1) + " \u00b0C" },
        "ram":  { top: "󰘚",  bottom: root.percent(SysStats.memUsage), glyph: true,
                  tip: "Memory\n" + root.humanBytes(SysStats.memUsedBytes) + " / " + root.humanBytes(SysStats.memTotalBytes) },
        "swap": { top: "󰌢", bottom: root.percent(SysStats.swapUsage), glyph: true,
                  tip: "Swap " + root.percent(SysStats.swapUsage) },
        "disk": { top: "󰋊", bottom: root.percent(SysStats.diskUsage), glyph: true,
                  tip: "Root filesystem\n" + root.humanBytes(SysStats.diskUsedBytes) + " / " + root.humanBytes(SysStats.diskTotalBytes) },
        "load": { top: "󰓅", bottom: root.percent(SysStats.load / SysStats.cores), glyph: true,
                  tip: "1 minute load average\n" + SysStats.load.toFixed(2) + " of " + SysStats.cores + " cores" },
        "net":  {
            top: "\u2193" + root.humanize(SysStats.rxRate),
            bottom: "\u2191" + root.humanize(SysStats.txRate),
            glyph: false,
                  tip: "Network\nDown " + root.humanize(SysStats.rxRate) + "/s\nUp " + root.humanize(SysStats.txRate) + "/s"
        }
    })

    // une entree inconnue dans le JSON est ignoree plutot que d'afficher
    // un trou ou de casser le widget
    readonly property var entries: (Config.stats ?? []).filter(k => root.definitions[k] !== undefined)

    Repeater {
        model: root.entries

        Hoverable {
            id: entry
            required property string modelData
            readonly property var def: root.definitions[entry.modelData]
            // le fond de survol deborde moins ici : les entrees sont voisines
            padding: 4
            tooltip: entry.def.tip ?? ""

        ColumnLayout {
            spacing: entry.def.glyph ? -root.size * 0.25 : -root.labelSize * 0.3

            Text {
                Layout.alignment: Qt.AlignHCenter
                // largeur figee sur les seules valeurs variables : un debit
                // passe de "378" a "1.2M", un pourcentage plafonne a quatre
                // caracteres et se dimensionne tout seul
                Layout.preferredWidth: entry.def.glyph ? -1 : root.labelSize * 2.8
                horizontalAlignment: Text.AlignLeft
                text: entry.def.top
                font.family: entry.def.glyph ? Theme.font : Theme.fontMono
                font.pixelSize: entry.def.glyph ? root.size * 1.25 : root.labelSize
                color: Theme.fg
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: entry.def.glyph ? -1 : root.labelSize * 2.8
                horizontalAlignment: Text.AlignLeft
                text: entry.def.bottom
                font.family: Theme.fontMono
                font.pixelSize: root.labelSize
                color: Theme.fg
            }
        }
        }
    }
}
