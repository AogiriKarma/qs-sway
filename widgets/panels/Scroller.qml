import QtQuick
import qs.services

// Zone defilante a hauteur plafonnee : le panneau grandit avec son contenu
// jusqu'a maxHeight, au-dela quoi on fait defiler. Sans plafond, une longue
// liste de reseaux ferait une bulle plus haute que l'ecran.
//
// Contrat, comme Pill : un seul enfant direct, qui declare sa taille.
Flickable {
    id: root

    default property alias content: holder.data
    property int maxHeight: 260

    readonly property Item item: holder.children[0] ?? null

    implicitWidth: root.item?.implicitWidth ?? 0
    implicitHeight: Math.min(root.item?.implicitHeight ?? 0, root.maxHeight)

    contentWidth: root.width
    contentHeight: root.item?.implicitHeight ?? 0
    clip: true
    // sans rebond : dans une bulle de 260 px, l'elastique donne l'impression
    // que le panneau se decolle
    boundsBehavior: Flickable.StopAtBounds

    Item {
        id: holder
        width: root.width
        height: root.item?.implicitHeight ?? 0
    }
}
