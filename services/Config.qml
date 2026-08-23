pragma Singleton
import Quickshell

// Preferences utilisateur.
//
// Distinct de Theme, qui decrit une palette et des fontes : ici on ne
// stocke que des choix de comportement ou de forme, ceux qu'un
// utilisateur peut vouloir changer sans rien connaitre du reste.
//
// Quickshell recharge a chaque sauvegarde, donc modifier ce fichier
// suffit a voir le resultat, sans redemarrer la barre.
Singleton {
    // Vocabulaire de formes de tout le shell : capsules et cercles, ou
    // angles vifs. Gouverne les bulles, les pastilles de workspace et
    // l'avatar — l'option ne vaut que si elle est appliquee partout, sinon
    // il reste des ronds isoles qui jurent avec le reste.
    //
    // Les angles vifs s'accordent avec des fenetres non arrondies, ce que
    // sway ne sait de toute facon pas faire.
    property bool rounded: true
}
