pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Reactive Color Properties (Defaults to Catppuccin Mocha-ish)
    property color background: "#11111b"
    property color surface: "#1e1e2e"
    property color surface_variant: "#313244"
    property color accent: "#cba6f7"
    property color primary: "#cba6f7"
    property color text: "#cdd6f4"
    property color text_dim: "#6c7086"
    property color error: "#f38ba8"
    property color success: "#a6e3a1"

    FileView {
        id: colorFile
        path: "/home/zoro/.config/quickshell/colors.json"
        onLoaded: updateColors()
    }

    function updateColors() {
        try {
            var data = JSON.parse(colorFile.text()).colors
            background = data.background
            surface = data.surface
            surface_variant = data.surface_variant
            accent = data.accent
            primary = data.primary
            text = data.text
            text_dim = data.text_dim
            error = data.error
            success = data.success
            console.log("[Theme] Colors updated from JSON")
        } catch(e) {
            console.error("[Theme] Failed to parse colors.json:", e)
        }
    }
    
    // Auto-darken background for "little dark" feel
    readonly property color backgroundDark: Qt.darker(background, 1.2)
    readonly property color surfaceDark: Qt.darker(surface, 1.1)
}
