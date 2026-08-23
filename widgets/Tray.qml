import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.I3
import QtQuick
import qs.services

Row {
    id: root

    property int size: 18
    // display() ouvre un menu natif : il lui faut la fenetre d'accueil,
    // qu'on lui passe depuis shell.qml (pas d'attachement QsWindow en 0.3.1)
    property var window

    spacing: 10
    // pas d'appli en tray -> pas de trou dans la bulle
    visible: SystemTray.items.values.length > 0

    // Un seul menu ouvert a la fois.
    //
    // Deux popups a grab simultanes sont interdits par le protocole Wayland :
    // le second se retrouve reparente sur le premier, et fermer l'un detruit
    // l'autre. On ferme donc explicitement le precedent avant d'ouvrir.
    property var currentMenu: null

    function showMenu(menu) {
        if (root.currentMenu && root.currentMenu !== menu)
            root.currentMenu.visible = false
        root.currentMenu = menu
        menu.visible = true
    }

    function hideMenu(menu) {
        menu.visible = false
        if (root.currentMenu === menu)
            root.currentMenu = null
    }

    // Le tray ne donne ni pid ni nom de bus : on rapproche son id/title
    // de l'app_id sway par comparaison de prefixe, apres normalisation.
    // "discord_status_icon_1" -> "discordstatusicon1" commence par "discord".
    function normalize(s) {
        return (s ?? "").toLowerCase().replace(/[^a-z0-9]/g, "")
    }

    function findWindow(trayItem) {
        const hints = [trayItem.id, trayItem.title].map(root.normalize).filter(h => h)
        for (const w of SwayTree.windows) {
            const app = root.normalize(w.app)
            if (!app)
                continue
            for (const h of hints)
                if (h.startsWith(app) || app.startsWith(h))
                    return w
        }
        return null
    }

    Repeater {
        model: SystemTray.items

        MouseArea {
            id: item
            required property SystemTrayItem modelData

            // une appli qui n'annonce pas de nom de theme envoie une image
            // brute, qui court-circuite le theme d'icones du systeme
            readonly property bool pixmapIcon: !item.modelData.icon.startsWith("image://icon/")

            // Icone deduite de l'appli elle-meme, par le meme chemin que
            // Workspaces : app_id sway -> entree desktop -> nom d'icone.
            // Le detour par DesktopEntries.applications.values est une
            // dependance artificielle : sans elle le binding ne se
            // reevalue pas quand les .desktop finissent de charger.
            readonly property string themedIcon: {
                if (!item.pixmapIcon)
                    return "" // l'appli annonce deja un nom de theme, et il
                              // est souvent dynamique (etat reseau, etc.)
                const entries = DesktopEntries.applications.values
                const win = root.findWindow(item.modelData)
                for (const hint of [win?.app, item.modelData.id, item.modelData.title]) {
                    if (!hint)
                        continue
                    const icon = (entries, DesktopEntries.heuristicLookup(hint)?.icon ?? "")
                    const path = icon ? Quickshell.iconPath(icon, true) : ""
                    if (path)
                        return path
                }
                return ""
            }

            // priorite au theme : la meme appli doit avoir la meme icone
            // partout dans la barre, workspaces compris
            readonly property string iconSource: item.themedIcon || item.modelData.icon

            implicitWidth: root.size
            implicitHeight: root.size
            anchors.verticalCenter: parent.verticalCenter
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

            function openMenu() {
                if (!item.modelData.hasMenu)
                    return
                // on lit l'etat reel du popup, pas un etat suppose : le
                // compositeur peut l'avoir ferme sans nous demander notre avis
                if (itemMenu.visible)
                    root.hideMenu(itemMenu)
                else
                    root.showMenu(itemMenu)
            }

            // Un popup par item, plutot qu'un seul recible a chaque clic :
            // chacun garde son propre QsMenuOpener, donc son menu est charge
            // une fois pour toutes (les menus DBusMenu sont paresseux, ils
            // n'arrivent qu'une fois l'opener attache au handle). Une fenetre
            // non visible ne coute qu'un objet, elle n'est pas mappee.
            TrayMenu {
                id: itemMenu
                menuHandle: item.modelData.menu
                anchorItem: item

                // resynchronisation : quand sway ferme le popup (clic
                // exterieur, perte du grab), personne ne previent le QML.
                // Sans ca, currentMenu resterait a jamais sur un popup ferme.
                onVisibleChanged: {
                    if (!visible && root.currentMenu === itemMenu)
                        root.currentMenu = null
                }
            }

            onClicked: event => {
                // onlyMenu : l'appli declare n'avoir aucune action de clic,
                // le menu est sa seule interaction
                if (event.button === Qt.RightButton || item.modelData.onlyMenu) {
                    item.openMenu()
                    return
                }
                if (event.button === Qt.MiddleButton) {
                    item.modelData.secondaryActivate()
                    return
                }
                // fenetre ouverte -> sway bascule dessus (et donc sur son
                // workspace) ; sinon on laisse l'appli se demerder pour en
                // creer une, c'est le role de Activate dans le protocole SNI
                const w = root.findWindow(item.modelData)
                if (w)
                    I3.dispatch(`[con_id=${w.conId}] focus`)
                else
                    item.modelData.activate()
            }

            IconImage {
                anchors.fill: parent
                source: item.iconSource
                asynchronous: true
            }
        }
    }
}
