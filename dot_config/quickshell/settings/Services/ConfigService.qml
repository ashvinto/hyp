pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Properties
    property bool zenMode: false
    property real dockScale: 1.3
    property real glassOpacity: 0.85
    property bool showTaskbar: true
    property int nightLightWarmth: 6500
    property real softwareDim: 1.0 // This now controls Hardware Brightness
    property bool blurEnabled: false

    property bool _loading: false

    FileView {
        id: configFile
        path: "/home/zoro/.config/quickshell/config.json"
        onLoaded: root.load()
        onTextChanged: root.load()
    }

    function load() {
        try {
            if (configFile.text() === "") return;
            _loading = true
            var data = JSON.parse(configFile.text())
            
            if (data.zenMode !== undefined) zenMode = data.zenMode
            if (data.dockScale !== undefined) dockScale = data.dockScale
            if (data.glassOpacity !== undefined) glassOpacity = data.glassOpacity
            if (data.showTaskbar !== undefined) showTaskbar = data.showTaskbar
            if (data.nightLightWarmth !== undefined) nightLightWarmth = data.nightLightWarmth
            if (data.softwareDim !== undefined) softwareDim = data.softwareDim
            if (data.blurEnabled !== undefined) blurEnabled = data.blurEnabled
            
            _loading = false
        } catch(e) {
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
            "blurEnabled": blurEnabled
        }
        var jsonStr = JSON.stringify(data, null, 4)
        Quickshell.execDetached(["bash", "-c", "echo '" + jsonStr + "' > /home/zoro/.config/quickshell/config.json"])
    }

    onZenModeChanged: save()
    onDockScaleChanged: save()
    onGlassOpacityChanged: save()
    onShowTaskbarChanged: save()
    onNightLightWarmthChanged: save()
    onSoftwareDimChanged: save()
    onBlurEnabledChanged: save()

    function toggleZen() {
        zenMode = !zenMode
        Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/zen_mode.sh"])
    }

    function setNightLight(value) {
        if (Math.abs(nightLightWarmth - value) > 10) {
            nightLightWarmth = value
            // Only control warmth via shader, brightness handled by brightnessctl
            Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/shader_man.sh warm " + Math.round(value)])
        }
    }

    function setDimming(value) {
        if (Math.abs(softwareDim - value) > 0.01) {
            softwareDim = value
            // Use hardware brightness instead of software shader
            // Ensure a minimum of 1% so screen doesn't go black
            var percent = Math.max(1, Math.round(value * 100))
            Quickshell.execDetached(["brightnessctl", "set", percent + "%"])
        }
    }
}