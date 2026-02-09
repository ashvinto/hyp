pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Properties with Defaults
    property bool zenMode: false
    property real dockScale: 1.3
    property real glassOpacity: 0.85
    property bool showTaskbar: true
    property int nightLightWarmth: 6500
    property real softwareDim: 1.0
    
    // Hyprland Specific Defaults
    property int hyprRounding: 12
    property int hyprGapsIn: 5
    property int hyprGapsOut: 10
    property bool hyprBlur: true

    property bool _loading: false

    FileView {
        id: configFile
        path: "/home/zoro/.config/quickshell/config.json"
        onLoaded: root.load()
        onTextChanged: root.load()
    }

    function load() {
        try {
            var raw = configFile.text()
            if (!raw || raw === "") return;
            var data = JSON.parse(raw)
            _loading = true
            
            // Core
            if (data.zenMode !== undefined) zenMode = data.zenMode
            if (data.dockScale !== undefined) dockScale = data.dockScale
            if (data.glassOpacity !== undefined) glassOpacity = data.glassOpacity
            if (data.showTaskbar !== undefined) showTaskbar = data.showTaskbar
            if (data.nightLightWarmth !== undefined) nightLightWarmth = data.nightLightWarmth
            if (data.softwareDim !== undefined) softwareDim = data.softwareDim
            
            // Hyprland
            if (data.hyprRounding !== undefined) hyprRounding = data.hyprRounding
            if (data.hyprGapsIn !== undefined) hyprGapsIn = data.hyprGapsIn
            if (data.hyprGapsOut !== undefined) hyprGapsOut = data.hyprGapsOut
            if (data.hyprBlur !== undefined) hyprBlur = data.hyprBlur
            else if (data.blurEnabled !== undefined) hyprBlur = data.blurEnabled // Migration
            
            console.log("[ConfigService] Loaded configuration from JSON")
            _loading = false
        } catch(e) {
            console.error("[ConfigService] Load failed:", e)
            _loading = false
        }
    }

    function save() {
        if (_loading) return;
        var data = {
            "zenMode": zenMode,
            "dockScale": dockScale,
            "glassOpacity": glassOpacity,
            "showTaskbar": showTaskbar,
            "nightLightWarmth": nightLightWarmth,
            "softwareDim": softwareDim,
            "hyprRounding": hyprRounding,
            "hyprGapsIn": hyprGapsIn,
            "hyprGapsOut": hyprGapsOut,
            "hyprBlur": hyprBlur
        }
        var jsonStr = JSON.stringify(data, null, 4)
        console.log("[ConfigService] Saving configuration to JSON...")
        Quickshell.execDetached(["bash", "-c", "echo '" + jsonStr + "' > /home/zoro/.config/quickshell/config.json"])
    }

    onZenModeChanged: save()
    onDockScaleChanged: save()
    onGlassOpacityChanged: save()
    onShowTaskbarChanged: save()
    onNightLightWarmthChanged: save()
    onSoftwareDimChanged: save()
    
    // Hyprland Handlers
    onHyprRoundingChanged: {
        Quickshell.execDetached(["hyprctl", "keyword", "decoration:rounding", hyprRounding.toString()])
        save()
    }
    onHyprGapsInChanged: {
        Quickshell.execDetached(["hyprctl", "keyword", "general:gaps_in", hyprGapsIn.toString()])
        save()
    }
    onHyprGapsOutChanged: {
        Quickshell.execDetached(["hyprctl", "keyword", "general:gaps_out", hyprGapsOut.toString()])
        save()
    }
    onHyprBlurChanged: {
        var val = hyprBlur ? "true" : "false"
        Quickshell.execDetached(["hyprctl", "keyword", "decoration:blur:enabled", val])
        save()
    }

    function toggleZen() {
        zenMode = !zenMode
        Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/zen_mode.sh"])
    }

    function setNightLight(value) {
        if (Math.abs(nightLightWarmth - value) > 10) {
            nightLightWarmth = value
            Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/shader_man.sh warm " + Math.round(value)])
        }
    }

    function setDimming(value) {
        if (Math.abs(softwareDim - value) > 0.01) {
            softwareDim = value
            Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/shader_man.sh dim " + Math.round(value * 100)])
        }
    }
}