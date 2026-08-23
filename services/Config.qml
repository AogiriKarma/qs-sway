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
    // Bulles en capsule (arrondi complet) ou a angles vifs.
    // Les angles vifs s'accordent avec des fenetres non arrondies,
    // ce que sway ne sait de toute facon pas faire.
    property bool roundedPills: true
}
