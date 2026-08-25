pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import QtQuick

// Statistiques systeme echantillonnees depuis /proc et /sys.
//
// Toutes ces valeurs sont des COMPTEURS CUMULATIFS : ni /proc/stat ni les
// statistiques reseau ne donnent un taux, seulement un total depuis le
// demarrage. Le service en fait des taux par difference entre deux mesures,
// et jette la premiere, qui n'a pas de precedent auquel se comparer.
Singleton {
    id: root

    // taux d'occupation, en 0-1 comme UPower et PipeWire
    property real cpuUsage: 0
    property real memUsage: 0
    property real memUsedBytes: 0
    property real memTotalBytes: 0

    // debit reseau en octets par seconde
    property real rxRate: 0
    property real txRate: 0

    // temperature du processeur, en degres
    property real cpuTemp: 0
    // remplissage de la racine, en 0-1
    property real diskUsage: 0
    property real diskUsedBytes: 0
    property real diskTotalBytes: 0
    property real swapUsage: 0
    // charge moyenne sur 1 minute : nombre moyen de processus qui veulent
    // tourner. Ne se lit que rapportee au nombre de coeurs, d'ou `cores`.
    property real load: 0
    property int cores: 1

    readonly property int interval: 2000

    // interface portant le trafic : le filaire prime s'il est branche
    readonly property var devices: Networking.devices.values
    readonly property var activeDevice: root.devices.find(d => d.type === DeviceType.Wired && d.connected)
        ?? root.devices.find(d => d.connected)
        ?? null
    readonly property string iface: root.activeDevice?.name ?? ""

    property var prevCpu: null
    property real prevRx: -1
    property real prevTx: -1

    // La numerotation hwmon n'est pas stable d'un demarrage a l'autre :
    // k10temp peut etre hwmon7 aujourd'hui et hwmon3 demain. On resout donc
    // le capteur par son NOM, une seule fois, au lancement.
    property string tempPath: ""

    Process {
        running: true
        command: ["sh", "-c", "for h in /sys/class/hwmon/hwmon*; do echo \"$(cat $h/name 2>/dev/null) $h\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const found = {}
                for (const line of text.trim().split("\n")) {
                    const [name, path] = line.split(" ")
                    if (name && path)
                        found[name] = path
                }
                // par ordre de pertinence : capteur AMD, capteur Intel,
                // puis la sonde ACPI generique en dernier recours
                for (const name of ["k10temp", "coretemp", "thinkpad", "acpitz"]) {
                    if (found[name]) {
                        root.tempPath = found[name] + "/temp1_input"
                        return
                    }
                }
            }
        }
    }

    FileView {
        id: tempFile
        path: root.tempPath
        blockLoading: true
        printErrors: false
    }

    // df plutot que /proc : le taux de remplissage demande un statvfs,
    // qu'aucun fichier de /proc n'expose. Rythme lent, ca bouge peu.
    Process {
        id: dfProc
        command: ["df", "-B1", "--output=size,used", "/"]
        stdout: StdioCollector {
            onStreamFinished: {
                const nums = text.trim().split("\n").pop().trim().split(/\s+/).map(Number)
                if (nums.length >= 2 && nums[0] > 0) {
                    root.diskTotalBytes = nums[0]
                    root.diskUsedBytes = nums[1]
                    root.diskUsage = nums[1] / nums[0]
                }
            }
        }
    }

    Timer {
        interval: 30000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: dfProc.running = true
    }

    FileView { id: loadFile; path: "/proc/loadavg"; blockLoading: true; printErrors: false }
    FileView { id: statFile; path: "/proc/stat"; blockLoading: true; printErrors: false }
    FileView { id: memFile; path: "/proc/meminfo"; blockLoading: true; printErrors: false }
    FileView {
        id: rxFile
        path: root.iface ? `/sys/class/net/${root.iface}/statistics/rx_bytes` : ""
        blockLoading: true
        printErrors: false
    }
    FileView {
        id: txFile
        path: root.iface ? `/sys/class/net/${root.iface}/statistics/tx_bytes` : ""
        blockLoading: true
        printErrors: false
    }

    function sampleCpu() {
        const lines = statFile.text().split("\n")
        // les lignes "cpu0", "cpu1"... donnent le nombre de coeurs, sans
        // avoir a lire /proc/cpuinfo ni lancer nproc
        const cores = lines.filter(l => /^cpu\d/.test(l)).length
        if (cores > 0)
            root.cores = cores
        // premiere ligne de /proc/stat : "cpu  user nice system idle iowait ..."
        const line = lines[0]
        const parts = line.trim().split(/\s+/).slice(1).map(Number)
        if (parts.length < 5 || parts.some(isNaN))
            return
        // iowait compte comme du repos : le processeur n'y calcule rien
        const idle = parts[3] + parts[4]
        const total = parts.reduce((a, b) => a + b, 0)

        if (root.prevCpu) {
            const dTotal = total - root.prevCpu.total
            const dIdle = idle - root.prevCpu.idle
            if (dTotal > 0)
                root.cpuUsage = Math.max(0, Math.min(1, 1 - dIdle / dTotal))
        }
        root.prevCpu = { total: total, idle: idle }
    }

    function sampleTemp() {
        const raw = parseInt(tempFile.text())
        // les capteurs hwmon rapportent des milli-degres
        if (!isNaN(raw))
            root.cpuTemp = raw / 1000
    }

    function sampleLoad() {
        const first = parseFloat(loadFile.text().split(" ")[0])
        if (!isNaN(first))
            root.load = first
    }

    function sampleMem() {
        const text = memFile.text()
        const total = /MemTotal:\s+(\d+)/.exec(text)
        // MemAvailable, pas MemFree : le cache est reutilisable a la demande,
        // le compter comme occupe afficherait un systeme sature en permanence
        const avail = /MemAvailable:\s+(\d+)/.exec(text)
        if (!total || !avail)
            return
        root.memTotalBytes = parseInt(total[1]) * 1024
        root.memUsedBytes = root.memTotalBytes - parseInt(avail[1]) * 1024
        root.memUsage = root.memTotalBytes > 0 ? root.memUsedBytes / root.memTotalBytes : 0

        const swapTotal = /SwapTotal:\s+(\d+)/.exec(text)
        const swapFree = /SwapFree:\s+(\d+)/.exec(text)
        if (swapTotal && swapFree && parseInt(swapTotal[1]) > 0)
            root.swapUsage = 1 - parseInt(swapFree[1]) / parseInt(swapTotal[1])
    }

    function sampleNet() {
        const rx = parseInt(rxFile.text())
        const tx = parseInt(txFile.text())
        if (isNaN(rx) || isNaN(tx))
            return
        // un compteur qui recule signale une interface redemarree
        if (root.prevRx >= 0 && rx >= root.prevRx) {
            root.rxRate = (rx - root.prevRx) * 1000 / root.interval
            root.txRate = (tx - root.prevTx) * 1000 / root.interval
        }
        root.prevRx = rx
        root.prevTx = tx
    }

    Timer {
        interval: root.interval
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            statFile.reload()
            memFile.reload()
            loadFile.reload()
            root.sampleCpu()
            root.sampleMem()
            root.sampleLoad()
            if (root.tempPath) {
                tempFile.reload()
                root.sampleTemp()
            }
            if (root.iface) {
                rxFile.reload()
                txFile.reload()
                root.sampleNet()
            }
        }
    }
}
