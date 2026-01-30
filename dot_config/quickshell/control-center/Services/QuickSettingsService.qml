pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool wifiEnabled: false
    property bool btEnabled: false
    property bool nightLightEnabled: false
    property bool dndEnabled: false
    property int batteryLevel: 0
    property bool isCharging: false

    function toggleWifi() { 
        Quickshell.execDetached(["sh", "-c", "nmcli radio wifi | grep -q 'enabled' && nmcli radio wifi off || nmcli radio wifi on"])
        wifiEnabled = !wifiEnabled
        wifiChecker.running = true
    }
    
    function toggleBluetooth() { 
        Quickshell.execDetached(["sh", "-c", "rfkill unblock bluetooth; bluetoothctl show | grep -q 'Powered: yes' && bluetoothctl power off || bluetoothctl power on"])
        btEnabled = !btEnabled
        btChecker.running = true
    }

    function toggleNightLight() {
        if (nightLightEnabled) {
            Quickshell.execDetached(["pkill", "wlsunset"])
            nightLightEnabled = false
        } else {
            Quickshell.execDetached(["wlsunset", "-t", "4500", "-T", "6500"])
            nightLightEnabled = true
        }
        nightLightChecker.running = true
    }

    function toggleDnd() {
        Quickshell.execDetached(["dunstctl", "set-paused", "toggle"])
        dndEnabled = !dndEnabled
        dndChecker.running = true
    }

    function lock() { Quickshell.execDetached(["hyprlock"]) }
    function logout() { Quickshell.execDetached(["hyprctl", "dispatch", "exit"]) }
    function shutdown() { Quickshell.execDetached(["shutdown", "now"]) }
    function reboot() { Quickshell.execDetached(["reboot"]) }

    function updateStatus() {
        batteryChecker.running = false; batteryChecker.running = true
        wifiChecker.running = false; wifiChecker.running = true
        btChecker.running = false; btChecker.running = true
        nightLightChecker.running = false; nightLightChecker.running = true
        dndChecker.running = false; dndChecker.running = true
    }

    Process {
        id: batteryChecker
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1; cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    var lines = text.trim().split("\n")
                    if (lines.length >= 1) root.batteryLevel = parseInt(lines[0]) || 0
                    if (lines.length >= 2) root.isCharging = lines[1].trim() === "Charging"
                }
            }
        }
    }

    Process {
        id: wifiChecker
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    root.wifiEnabled = text.includes("enabled")
                }
            }
        }
    }

    Process {
        id: btChecker
        command: ["bash", "-c", "bluetoothctl show 2>/dev/null | grep 'Powered:'"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) root.btEnabled = text.includes("yes")
            }
        }
    }

    Process {
        id: nightLightChecker
        command: ["pgrep", "wlsunset"]
        stdout: StdioCollector {
            onStreamFinished: root.nightLightEnabled = (text && text.trim() !== "")
        }
    }

    Process {
        id: dndChecker
        command: ["dunstctl", "is-paused"]
        stdout: StdioCollector {
            onStreamFinished: root.dndEnabled = (text && text.trim() === "true")
        }
    }

    // Frequent heartbeats for snappy UI (2s)
    Timer { 
        interval: 2000; running: true; repeat: true
        onTriggered: {
            wifiChecker.running = true
            btChecker.running = true
            nightLightChecker.running = true
            dndChecker.running = true
        }
    }

    Timer { 
        interval: 10000; running: true; repeat: true
        onTriggered: batteryChecker.running = true 
    }

    Component.onCompleted: updateStatus()
}
