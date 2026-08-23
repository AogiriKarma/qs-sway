pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // { num: ["app_id", ...] } — ex: wsApps[1] === ["code-oss", "kitty"]
    property var wsApps: ({})

    // [{ app, conId, pid, workspace, title }, ...] — toutes les fenetres,
    // a plat. conId est l'identifiant sway, utilisable en [con_id=N].
    property var windows: []

    function collectWindows(node, wsNum, acc) {
        const kids = (node.nodes ?? []).concat(node.floating_nodes ?? [])
        for (const child of kids) {
            // app_id pour les fenêtres natives Wayland,
            // window_properties.class en fallback pour XWayland
            const app = child.app_id ?? child.window_properties?.class
            if (app)
                acc.push({
                    app: app,
                    conId: child.id,
                    pid: child.pid ?? -1,
                    workspace: wsNum,
                    title: child.name ?? ""
                })
            collectWindows(child, wsNum, acc)
        }
    }

    Process {
        id: treeProc
        command: ["swaymsg", "-t", "get_tree", "--raw"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let tree
                try {
                    tree = JSON.parse(text)
                } catch (e) {
                    console.warn("get_tree: JSON invalide", e)
                    return
                }

                const apps = {}
                const wins = []
                for (const output of tree.nodes) {
                    for (const ws of output.nodes) {
                        // num > 0 ecarte deja le scratchpad (__i3_scratch, num -1)
                        // et les workspaces nommes
                        if (ws.type !== "workspace" || !(ws.num > 0))
                            continue
                        const acc = []
                        collectWindows(ws, ws.num, acc)
                        apps[ws.num] = acc.map(w => w.app)
                        wins.push(...acc)
                    }
                }
                // reassignation d'un bloc : QML ne voit pas les mutations en place
                root.wsApps = apps
                root.windows = wins
            }
        }
    }

    // Debounce : un move de fenetre genere plusieurs events d'affilee,
    // pas besoin de re-parser l'arbre 4 fois en 10ms
    Timer {
        id: refreshDebounce
        interval: 50
        onTriggered: treeProc.running = true
    }

    Process {
        id: subProc
        command: ["swaymsg", "-t", "subscribe", "-m", "[\"window\",\"workspace\"]"]
        running: true
        stdout: SplitParser {
            onRead: refreshDebounce.restart()
        }
    }
}