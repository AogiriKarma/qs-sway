# qs-sway

Barre de statut [Quickshell](https://quickshell.org) pour sway.

## Aperçu

Quatre bulles, sur une barre horizontale (haut) ou verticale (gauche) :

| Bulle | Contenu |
|---|---|
| Utilisateur | avatar `~/.face` et nom d'utilisateur |
| Statistiques | CPU, température, mémoire, disque, débit réseau |
| Workspaces | dix pastilles, icône de la première fenêtre de chaque workspace |
| État | réseau, bluetooth, volume, batterie, horloge, alimentation |

La bulle d'état **se transforme en panneau** au clic sur un de ses widgets,
par-dessus les fenêtres et sans les décaler. Six pages : calendrier, mixer
audio, appareils bluetooth, réseaux wifi et ethernet, batterie, session.

Le tray apparaît dans sa propre bulle quand une application s'y enregistre,
avec ses menus redessinés aux couleurs de la barre.

## Dépendances

```sh
pacman -S quickshell upower bluez bluez-utils power-profiles-daemon qt6ct
systemctl enable --now bluetooth power-profiles-daemon
```

`bluez` alimente la page bluetooth, `power-profiles-daemon` les trois
profils de la page batterie, `upower` la batterie elle-même. `qt6ct` sert
uniquement à faire lire un thème d'icônes à Qt (voir plus bas).

## Installation

```sh
git clone <ce-depot> ~/.config/quickshell
```

Puis, dans la config sway :

```
# la barre reserve deja son espace en haut, l'ecart externe y ferait doublon
gaps top 0px
exec env QT_QPA_PLATFORMTHEME=qt6ct qs
```

## Thème d'icônes

Sans pont, Qt ignore le thème d'icônes du système et ne trouve que
`hicolor` — les icônes d'applications s'affichent alors telles que chaque
paquet les fournit, en couleurs. Pour un rendu homogène :

```sh
# un theme monochrome, par exemple
git clone https://github.com/suru-plus/suru-plus-aspromauros
cp -r suru-plus-aspromauros/Suru++-Asprómauros ~/.local/share/icons/
```

```ini
# ~/.config/qt6ct/qt6ct.conf
[Appearance]
icon_theme=Suru++-Asprómauros
```

C'est la variable `QT_QPA_PLATFORMTHEME=qt6ct` de la ligne `exec` qui
active ce pont.

## Avatar

La bulle de gauche lit `~/.face`, la convention historique des gestionnaires
de session. Sans fichier, elle affiche l'initiale du nom d'utilisateur, et
l'image apparaît dès qu'elle est déposée, sans redémarrage.

## Configuration

`~/.config/quickshell/config.json` est écrit au premier lancement avec les
valeurs par défaut. Les modifier prend effet à la sauvegarde.

```json
{
    "barEdge": "top",
    "barSize": 80,
    "rounded": true,
    "stats": ["cpu", "temp", "ram", "disk", "net"]
}
```

- `barEdge` — `"top"` ou `"left"`.
- `barSize` — épaisseur de la barre ; toutes les tailles en dérivent.
- `rounded` — capsules et cercles, ou angles vifs.
- `stats` — statistiques affichées et leur ordre, parmi `cpu`, `temp`,
  `ram`, `swap`, `disk`, `load`, `net`. Une clé inconnue est ignorée.

Les valeurs déclarées dans `services/Config.qml` restent les défauts : le
fichier ne fait que les écraser, et une clé absente retombe sur sa valeur
d'origine.

## Structure

```
shell.qml            la barre : fenetre, bulles, ancrages
services/            faits rapportes au reste du shell
  Config.qml         preferences utilisateur, adossees au JSON
  Theme.qml          palette et fontes
  SwayTree.qml       arbre sway, rafraichi par abonnement aux evenements
  SysStats.qml       /proc et /sys, echantillonnes
widgets/             affichage dans la barre
  panels/            pages de la bulle d'etat
```

Un service rapporte des faits, un widget décide de ce qu'il en montre.

## Notes de développement

Quickshell recharge les **fichiers** à chaud, mais pas la **liste des types**
d'un module : ajouter un fichier au `qmldir` ou une propriété à un widget
demande un redémarrage de `qs`. Modifier une valeur, non.

Les pages de `widgets/panels/` sont chargées par URL, donc mises en cache
par le moteur : les modifier demande aussi un redémarrage.
