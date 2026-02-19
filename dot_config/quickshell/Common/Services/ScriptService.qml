pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    function runScript(name) {
        var path = "/home/zoro/.config/hypr/scripts/" + name
        console.log("[ScriptService] Running: " + path)
        Quickshell.execDetached(["bash", path])
    }

    // UI Helpers for specific script actions
    function toggleRetro() { runScript("toggle-retro.sh") }
    function toggleFocus() { runScript("toggle-focus.sh") }
    function toggleZen() { runScript("zen_mode.sh") }
    function openWallpaperPicker() { runScript("wppicker.sh") }
    function toggleAirplaneMode() { runScript("AirplaneMode.sh") }
    function controlLights(action) { 
        var path = "/home/zoro/.config/hypr/scripts/control_lights.sh"
        console.log("[ScriptService] Running Lights: " + path + " " + action)
        Quickshell.execDetached(["bash", path, action]) 
    }
    function restartWaybar() { runScript("wbrestart.sh") }
    function openKeybindViewer() { runScript("keybind_viewer.sh") }
    function openEmojiPicker() { runScript("emoji-picker.sh") }
}
