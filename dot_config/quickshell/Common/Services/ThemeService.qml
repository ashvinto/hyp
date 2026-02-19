pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Reactive Color Properties
    property color background: "#11111b"
    property color surface: "#1e1e2e"
    property color surface_variant: "#313244"
    property color accent: "#cba6f7"
    property color primary: "#cba6f7"
    property color text: "#cdd6f4"
    property color text_dim: "#6c7086"
    property color error: "#f38ba8"
    property color success: "#a6e3a1"

    signal themeChanged()

    property bool _loading: false

    FileView {
        id: colorFile
        path: "/home/zoro/.config/quickshell/colors.json"
        onLoaded: updateColors()
        onTextChanged: updateColors()
    }

    function updateColors() {
        if (_loading) return;
        try {
            var raw = colorFile.text()
            if (!raw || raw === "") return;
            var data = JSON.parse(raw).colors
            _loading = true
            background = data.background || background
            surface = data.surface || surface
            surface_variant = data.surface_variant || surface_variant
            accent = data.accent || accent
            primary = data.primary || primary
            text = data.text || text
            text_dim = data.text_dim || text_dim
            error = data.error || error
            success = data.success || success
            console.log("[ThemeService] Loaded colors from JSON")
            root.themeChanged()
            _loading = false
        } catch(e) {
            console.error("[ThemeService] Load failed:", e)
            _loading = false
        }
    }

    // Helper to get #RRGGBB hex string (avoiding alpha #AARRGGBB)
    function toHex(color) {
        var r = Math.round(color.r * 255).toString(16).padStart(2, '0')
        var g = Math.round(color.g * 255).toString(16).padStart(2, '0')
        var b = Math.round(color.b * 255).toString(16).padStart(2, '0')
        return "#" + r + g + b
    }

    function save() {
        if (_loading) return;
        
        var data = {
            "colors": {
                "background": toHex(background),
                "surface": toHex(surface),
                "surface_variant": toHex(surface_variant),
                "primary": toHex(primary),
                "accent": toHex(accent),
                "text": toHex(text),
                "text_dim": toHex(text_dim),
                "error": toHex(error),
                "success": toHex(success)
            }
        }
        var jsonStr = JSON.stringify(data, null, 2)
        console.log("[ThemeService] Saving colors to JSON...")
        Quickshell.execDetached(["bash", "-c", "echo '" + jsonStr + "' > /home/zoro/.config/quickshell/colors.json"])
    }

    onAccentChanged: {
        primary = accent
        save()
    }
    
    readonly property color backgroundDark: Qt.darker(background, 1.2)
    readonly property color surfaceDark: Qt.darker(surface, 1.1)
}
