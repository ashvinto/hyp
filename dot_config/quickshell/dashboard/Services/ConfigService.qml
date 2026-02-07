pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    
    // UI Settings
    property bool zenMode: false
    property real dockScale: 1.3
    property real glassOpacity: 0.85
    property bool showTaskbar: true
    
    // System Settings
    property int nightLightWarmth: 4000
    property real softwareDim: 1.0
    property bool blurEnabled: false

    // Persistence Logic (Simple file-based)
    function save() {
        var data = {
            "zenMode": zenMode,
            "dockScale": dockScale,
            "glassOpacity": glassOpacity,
            "showTaskbar": showTaskbar,
            "nightLightWarmth": nightLightWarmth,
            "softwareDim": softwareDim,
            "blurEnabled": blurEnabled
        }
        // Save to ~/.config/quickshell/config.json if needed
        console.log("Saving configuration...")
    }

    // Command Wrappers
    function toggleZen() {
        zenMode = !zenMode
        Quickshell.execDetached(["sh", "-c", "~/.config/hypr/scripts/zen_mode.sh"])
        save()
    }

    function setNightLight(value) {
        nightLightWarmth = value
        Quickshell.execDetached(["sh", "-c", "~/.config/hypr/scripts/shader_man.sh warm " + value])
    }

    function setDimming(value) {
        softwareDim = value
        Quickshell.execDetached(["sh", "-c", "~/.config/hypr/scripts/shader_man.sh dim " + value])
    }
}
