pragma Singleton
import Quickshell
import QtQuick

Singleton {
    readonly property string font: "Monofur Nerd Font Propo"
    readonly property string fontMono: "Monofur Nerd Font Mono"

    // fonds (alpha déplacé devant : RGBA sway -> AARRGGBB qml)
    readonly property color bg:      "#200b0c0d"
    readonly property color surface: "#20141618"
    readonly property color overlay: "#1D2023"

    // textes
    readonly property color fg:    "#C9CCCE"
    readonly property color muted: "#8A9093"
    readonly property color dim:   "#6E7477"

    // accents
    readonly property color accent:  "#FFFFFF"
    readonly property color glow:    "#E4E6E7"
    readonly property color special: "#A8E5E8"
    readonly property color warning: "#C9BCA7"
    readonly property color danger:  "#C9A7A7"
}