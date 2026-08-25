pragma Singleton
import Quickshell
import Quickshell.Io

// Preferences utilisateur, adossees a un fichier JSON.
//
// Distinct de Theme, qui decrit une palette et des fontes : ici on ne
// stocke que des choix de comportement ou de forme, ceux qu'un
// utilisateur peut vouloir changer sans rien connaitre du reste.
//
// Les valeurs declarees dans le JsonAdapter sont les DEFAUTS ; le fichier
// ne fait que les ecraser. Il est donc facultatif, et un depot clone
// fonctionne sans qu'on impose ses gouts a personne.
//
// Editer le JSON prend effet immediatement : ce sont des valeurs, pas des
// types. Ajouter une propriete ici, en revanche, demande un redemarrage de
// qs — Quickshell ne recompile les types d'un module qu'au lancement.
Singleton {
    id: root

    readonly property alias rounded: adapter.rounded
    readonly property alias barEdge: adapter.barEdge
    readonly property alias barSize: adapter.barSize

    // derive, donc absent du fichier : une seule source de verite
    readonly property bool vertical: adapter.barEdge === "left"

    FileView {
        path: `${Quickshell.env("HOME")}/.config/quickshell/config.json`

        // relecture a chaque sauvegarde du fichier
        watchChanges: true
        onFileChanged: reload()
        // et ecriture quand une valeur change depuis le QML, pour que le
        // fichier reste le reflet de l'etat courant
        onAdapterUpdated: writeAdapter()
        // premier lancement : on materialise les defauts sur le disque,
        // ce qui donne un fichier a editer plutot qu'une page blanche
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter()
        }

        JsonAdapter {
            id: adapter

            // Vocabulaire de formes de tout le shell : capsules et cercles,
            // ou angles vifs. Gouverne les bulles, les pastilles de
            // workspace et l'avatar — l'option ne vaut que si elle est
            // appliquee partout, sinon il reste des ronds isoles.
            property bool rounded: true

            // Bord de l'ecran ou la barre est ancree : "top" ou "left".
            // Chaine plutot que booleen : "bottom" et "right" viendront
            // sans renommer l'option ni inverser une logique de negation.
            property string barEdge: "top"

            // Epaisseur de la barre : hauteur si horizontale, largeur si
            // verticale. Toutes les tailles de widgets en derivent.
            property int barSize: 80
        }
    }
}
