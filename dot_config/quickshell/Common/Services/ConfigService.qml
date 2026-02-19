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
    property string profileIcon: "file:///home/zoro/.face"
    property string userAlias: "Zoro"

    // Hyprland Integration
    property int hyprRounding: 12
    property int hyprGapsIn: 5
    property int hyprGapsOut: 10
    property bool hyprBlur: true
    property int hyprBorderSize: 2
    property bool hyprShadows: true
    property bool hyprAnimations: true
    property real hyprOpacityActive: 1.0
    property real hyprOpacityInactive: 0.9
    property color hyprBorderActive: "#cba6f7"
    property color hyprBorderInactive: "#313244"

    // Input Settings
    property real mouseSensitivity: 0.0
    property bool naturalScroll: false

    property bool _loading: true // Start true to prevent save() during initial property assignments

    FileView {
        id: configFile
        path: "/home/zoro/.config/quickshell/config.json"
        onLoaded: root.load()
        onTextChanged: root.load()
    }

    function load() {
        try {
            var raw = configFile.text()
            if (raw === "" || raw === undefined) {
                _loading = false
                return
            }
            
            var data = JSON.parse(raw)
            _loading = true // Keep true while batch updating properties
            
            if (data.zenMode !== undefined) zenMode = data.zenMode
            if (data.dockScale !== undefined) dockScale = data.dockScale
            if (data.glassOpacity !== undefined) glassOpacity = data.glassOpacity
            if (data.showTaskbar !== undefined) showTaskbar = data.showTaskbar
            if (data.nightLightWarmth !== undefined) nightLightWarmth = data.nightLightWarmth
            if (data.softwareDim !== undefined) softwareDim = data.softwareDim
            if (data.blurEnabled !== undefined) blurEnabled = data.blurEnabled
            if (data.profileIcon !== undefined) profileIcon = data.profileIcon
            if (data.userAlias !== undefined) userAlias = data.userAlias
            
            // Hyprland
            if (data.hyprRounding !== undefined) hyprRounding = data.hyprRounding
            if (data.hyprGapsIn !== undefined) hyprGapsIn = data.hyprGapsIn
            if (data.hyprGapsOut !== undefined) hyprGapsOut = data.hyprGapsOut
            if (data.hyprBlur !== undefined) hyprBlur = data.hyprBlur
            if (data.hyprBorderSize !== undefined) hyprBorderSize = data.hyprBorderSize
            if (data.hyprShadows !== undefined) hyprShadows = data.hyprShadows
            if (data.hyprAnimations !== undefined) hyprAnimations = data.hyprAnimations
            if (data.hyprOpacityActive !== undefined) hyprOpacityActive = data.hyprOpacityActive
            if (data.hyprOpacityInactive !== undefined) hyprOpacityInactive = data.hyprOpacityInactive
            if (data.hyprBorderActive !== undefined) hyprBorderActive = data.hyprBorderActive
            if (data.hyprBorderInactive !== undefined) hyprBorderInactive = data.hyprBorderInactive
            
            // Input
            if (data.mouseSensitivity !== undefined) mouseSensitivity = data.mouseSensitivity
            if (data.naturalScroll !== undefined) naturalScroll = data.naturalScroll
            
            _loading = false
            syncAll()
        } catch(e) {
            _loading = false
            console.error("[ConfigService] Load failed:", e)
        }
    }

    function syncAll() {
        // Use a simple array of commands to avoid complex string escaping issues in batch
        var activeBorderHex = toHex(hyprBorderActive).replace("#", "0xff")
        var inactiveBorderHex = toHex(hyprBorderInactive).replace("#", "0xff")
        
        var commands = [
            "decoration:rounding " + hyprRounding,
            "general:gaps_in " + hyprGapsIn,
            "general:gaps_out " + hyprGapsOut,
            "decoration:blur:enabled " + (hyprBlur ? "true" : "false"),
            "general:border_size " + hyprBorderSize,
            "decoration:drop_shadow " + (hyprShadows ? "true" : "false"),
            "animations:enabled " + (hyprAnimations ? "true" : "false"),
            "decoration:active_opacity " + hyprOpacityActive.toFixed(2),
            "decoration:inactive_opacity " + hyprOpacityInactive.toFixed(2),
            "general:col.active_border " + activeBorderHex,
            "general:col.inactive_border " + inactiveBorderHex,
            "input:sensitivity " + mouseSensitivity.toFixed(2),
            "input:touchpad:natural_scroll " + (naturalScroll ? "true" : "false")
        ]

        for (var i = 0; i < commands.length; i++) {
            Quickshell.execDetached(["hyprctl", "keyword", commands[i].split(" ")[0], commands[i].split(" ")[1]])
        }
        
        Quickshell.execDetached(["bash", "-c", "/home/zoro/.config/hypr/scripts/shader_man.sh"])
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
            "blurEnabled": blurEnabled,
            "profileIcon": profileIcon,
            "userAlias": userAlias,
            "hyprRounding": hyprRounding,
            "hyprGapsIn": hyprGapsIn,
            "hyprGapsOut": hyprGapsOut,
            "hyprBlur": hyprBlur,
            "hyprBorderSize": hyprBorderSize,
            "hyprShadows": hyprShadows,
            "hyprAnimations": hyprAnimations,
            "hyprOpacityActive": hyprOpacityActive,
            "hyprOpacityInactive": hyprOpacityInactive,
            "hyprBorderActive": toHex(hyprBorderActive),
            "hyprBorderInactive": toHex(hyprBorderInactive),
            "mouseSensitivity": mouseSensitivity,
            "naturalScroll": naturalScroll
        }
        var jsonStr = JSON.stringify(data, null, 4)
        Quickshell.execDetached(["bash", "-c", "echo '" + jsonStr + "' > /home/zoro/.config/quickshell/config.json"])
    }

    function toHex(color) {
        var r = Math.round(color.r * 255).toString(16).padStart(2, '0')
        var g = Math.round(color.g * 255).toString(16).padStart(2, '0')
        var b = Math.round(color.b * 255).toString(16).padStart(2, '0')
        return "#" + r + g + b
    }

    onZenModeChanged: save()
    onDockScaleChanged: save()
    onGlassOpacityChanged: save()
    onShowTaskbarChanged: save()
    onNightLightWarmthChanged: save()
    onSoftwareDimChanged: save()
    onBlurEnabledChanged: save()
    onProfileIconChanged: save()
    onUserAliasChanged: save()
    
    onHyprRoundingChanged: { save(); Quickshell.execDetached(["hyprctl", "keyword", "decoration:rounding", hyprRounding.toString()]) }
    onHyprGapsInChanged: { save(); Quickshell.execDetached(["hyprctl", "keyword", "general:gaps_in", hyprGapsIn.toString()]) }
    onHyprGapsOutChanged: { save(); Quickshell.execDetached(["hyprctl", "keyword", "general:gaps_out", hyprGapsOut.toString()]) }
    onHyprBlurChanged: { save(); Quickshell.execDetached(["hyprctl", "keyword", "decoration:blur:enabled", hyprBlur ? "true" : "false"]) }
    onHyprBorderSizeChanged: { save(); Quickshell.execDetached(["hyprctl", "keyword", "general:border_size", hyprBorderSize.toString()]) }
    onHyprShadowsChanged: { save(); Quickshell.execDetached(["hyprctl", "keyword", "decoration:drop_shadow", hyprShadows ? "true" : "false"]) }
    onHyprAnimationsChanged: { save(); Quickshell.execDetached(["hyprctl", "keyword", "animations:enabled", hyprAnimations ? "true" : "false"]) }
    onHyprOpacityActiveChanged: {
        save()
        var val = hyprOpacityActive.toFixed(2)
        Quickshell.execDetached(["hyprctl", "keyword", "decoration:active_opacity", val])
    }
    onHyprOpacityInactiveChanged: {
        save()
        var val = hyprOpacityInactive.toFixed(2)
        Quickshell.execDetached(["hyprctl", "keyword", "decoration:inactive_opacity", val])
    }
    onHyprBorderActiveChanged: { 
        save()
        Quickshell.execDetached(["hyprctl", "keyword", "general:col.active_border", toHex(hyprBorderActive).replace("#", "0xff")]) 
    }
    onHyprBorderInactiveChanged: { 
        save()
        Quickshell.execDetached(["hyprctl", "keyword", "general:col.inactive_border", toHex(hyprBorderInactive).replace("#", "0xff")]) 
    }
    onMouseSensitivityChanged: { save(); Quickshell.execDetached(["hyprctl", "keyword", "input:sensitivity", mouseSensitivity.toFixed(2)]) }
    onNaturalScrollChanged: { save(); Quickshell.execDetached(["hyprctl", "keyword", "input:touchpad:natural_scroll", naturalScroll ? "true" : "false"]) }

    Connections {
        target: (typeof ThemeService !== "undefined") ? ThemeService : null
        function onAccentChanged() { if (!_loading) { hyprBorderActive = ThemeService.accent } }
    }

    function reloadShell() { Quickshell.execDetached(["bash", "-c", "pkill -f 'qs -c' && sleep 0.5 && ~/.config/hypr/scripts/shell-manager.sh"]) }
    function toggleZen() { zenMode = !zenMode; Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/zen_mode.sh"]) }
    function setNightLight(value) { if (Math.abs(nightLightWarmth - value) > 10) { nightLightWarmth = value; Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/shader_man.sh warm " + Math.round(value)]) } }
    function setDimming(value) { if (Math.abs(softwareDim - value) > 0.01) { softwareDim = value; var percent = Math.max(1, Math.round(value * 100)); Quickshell.execDetached(["brightnessctl", "set", percent + "%"]) } }
}
