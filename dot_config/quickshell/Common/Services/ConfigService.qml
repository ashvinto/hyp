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
    property real softwareDim: 1.0
    property bool blurEnabled: false

    property bool _loading: false

    // File Watcher
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
            
            console.log("[Config] Loaded configuration")
            _loading = false
        } catch(e) {
            console.error("[Config] Load failed:", e)
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
        
        // Debounce or immediate? Immediate for now.
        // Using bash to write file
        Quickshell.execDetached(["bash", "-c", "echo '" + jsonStr + "' > /home/zoro/.config/quickshell/config.json"])
    }

    // Auto-save on changes
    onZenModeChanged: save()
    onDockScaleChanged: save()
    onGlassOpacityChanged: save()
    onShowTaskbarChanged: save()
    onNightLightWarmthChanged: save()
    onSoftwareDimChanged: save()
    onBlurEnabledChanged: save()

    // Command Wrappers
    function toggleZen() {
        zenMode = !zenMode
        Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/zen_mode.sh"])
        // save() triggered by property change
    }

    function setNightLight(value) {
        // Only update if significantly changed to avoid spamming script
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
