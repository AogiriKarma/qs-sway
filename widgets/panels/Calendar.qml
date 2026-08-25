import QtQuick
import QtQuick.Layouts
import qs.services

// Calendrier mensuel, navigable. Entierement local : aucune API systeme,
// juste de l'arithmetique de dates.
ColumnLayout {
    id: root

    // premier jour du mois affiche ; on ne stocke jamais un "mois" seul,
    // une Date evite toute arithmetique manuelle sur les fins d'annee
    property date shown: new Date(new Date().getFullYear(), new Date().getMonth(), 1)

    readonly property date today: new Date()
    readonly property var locale: Qt.locale()

    // Lundi comme premier jour. getDay() renvoie 0 pour dimanche : on
    // decale pour que lundi vaille 0 et dimanche 6.
    readonly property int leading: (new Date(root.shown.getFullYear(), root.shown.getMonth(), 1).getDay() + 6) % 7
    readonly property int daysInMonth: new Date(root.shown.getFullYear(), root.shown.getMonth() + 1, 0).getDate()

    function shift(months) {
        root.shown = new Date(root.shown.getFullYear(), root.shown.getMonth() + months, 1)
    }

    function isToday(day) {
        return day === root.today.getDate()
            && root.shown.getMonth() === root.today.getMonth()
            && root.shown.getFullYear() === root.today.getFullYear()
    }

    spacing: 10

    // --- en-tete : mois et navigation
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            text: "‹"
            color: prevHover.hovered ? Theme.accent : Theme.muted
            font.family: Theme.font
            font.pixelSize: 20
            HoverHandler { id: prevHover }
            TapHandler { onTapped: root.shift(-1) }
        }

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: root.locale.standaloneMonthName(root.shown.getMonth()) + " " + root.shown.getFullYear()
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: 15
            font.bold: true
        }

        Text {
            text: "›"
            color: nextHover.hovered ? Theme.accent : Theme.muted
            font.family: Theme.font
            font.pixelSize: 20
            HoverHandler { id: nextHover }
            TapHandler { onTapped: root.shift(1) }
        }
    }

    // --- grille : 7 colonnes d'en-tete puis 42 cases
    GridLayout {
        columns: 7
        rowSpacing: 2
        columnSpacing: 2

        Repeater {
            model: 7
            Text {
                required property int index
                Layout.preferredWidth: 30
                horizontalAlignment: Text.AlignHCenter
                // dayName(1) = lundi ; on prend l'initiale
                text: root.locale.standaloneDayName((index + 1) % 7, Locale.ShortFormat).charAt(0)
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: 11
            }
        }

        Repeater {
            // 6 semaines : la hauteur du panneau ne change pas d'un mois a
            // l'autre, sinon le morphing sauterait a chaque navigation
            model: 42

            Rectangle {
                required property int index
                readonly property int day: index - root.leading + 1
                readonly property bool inMonth: day >= 1 && day <= root.daysInMonth

                Layout.preferredWidth: 30
                Layout.preferredHeight: 26
                radius: Config.rounded ? height / 2 : 4
                color: root.isToday(day) ? Theme.accent : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: parent.inMonth ? parent.day : ""
                    color: root.isToday(parent.day) ? Theme.overlay
                        : parent.inMonth ? Theme.fg
                        : Theme.dim
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                }
            }
        }
    }
}
