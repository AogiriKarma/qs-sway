import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import qs.services

Row {
    id: root

    property int size: 26
    // ~/.face est la convention Linux pour la photo de profil : c'est ce que
    // lisent SDDM, KDM et consorts. AccountsService la stocke ailleurs
    // (/var/lib/AccountsService/icons/<user>), mais c'est un chemin systeme.
    property string avatarPath: Quickshell.env("HOME") + "/.face"
    property string username: Quickshell.env("USER") ?? ""

    spacing: 8

    readonly property string details: root.username
        + (hostFile.loaded ? "@" + hostFile.text().trim() : "")

    FileView {
        id: hostFile
        path: "/etc/hostname"
        printErrors: false
    }

    // Sert uniquement a savoir si le fichier existe : une Image dont la
    // source est absente fait râler Qt dans la console. printErrors coupe
    // le bruit, watchChanges fait apparaitre l'avatar sans redemarrer.
    FileView {
        id: faceFile
        path: root.avatarPath
        printErrors: false
        watchChanges: true
    }

    // watchChanges ne surveille qu'un fichier existant : s'il n'y en a pas
    // encore, il n'y a rien a surveiller et l'avatar n'apparaitrait qu'au
    // prochain rechargement. On retente, et on s'arrete des qu'il est la.
    Timer {
        running: !faceFile.loaded
        interval: 3000
        repeat: true
        onTriggered: faceFile.reload()
    }

    ClippingRectangle {
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: root.size
        implicitHeight: root.size
        radius: Config.rounded ? width / 2 : 0
        color: Theme.surface

        Image {
            id: face
            anchors.fill: parent
            source: faceFile.loaded ? "file://" + root.avatarPath : ""
            // recadre au lieu de deformer si l'image n'est pas carree
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: face.status === Image.Ready
            // evite de decoder une photo pleine resolution pour 26 px
            sourceSize.width: root.size * 2
            sourceSize.height: root.size * 2
        }

        // repli tant qu'il n'y a pas de photo : l'initiale
        Text {
            anchors.centerIn: parent
            visible: !face.visible
            text: root.username.charAt(0).toUpperCase()
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: root.size * 0.55
            font.bold: true
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        // barre laterale : le nom ne rentre pas, l'avatar suffit
        visible: !Config.vertical
        text: root.username
        color: Theme.fg
        font.family: Theme.font
        font.pixelSize: root.size * 0.62
    }
}
