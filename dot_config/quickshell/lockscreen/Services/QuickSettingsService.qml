pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool wifiEnabled: false
    property bool btEnabled: false
    property int batteryLevel: 0
    property bool isCharging: false

    function toggleWifi() { Quickshell.execDetached(["sh", "-c", "nmcli radio wifi | grep -q 'enabled' && nmcli radio wifi off || nmcli radio wifi on"])}
    function toggleBluetooth() { Quickshell.execDetached(["sh", "-c", "bluetoothctl show | grep -q 'Powered: yes' && bluetoothctl power off || bluetoothctl power on"])}
    function lock() { Quickshell.execDetached(["hyprlock"])}
    function logout() { Quickshell.execDetached(["hyprctl", "dispatch", "exit"])}
    function shutdown() { Quickshell.execDetached(["shutdown", "now"])}
    function reboot() { Quickshell.execDetached(["reboot"])}

    // Persistent Process for Battery
    Process {
        id: batProc
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT1/capacity; cat /sys/class/power_supply/BAT1/status"]
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

    // Persistent Process for WiFi
    Process {
        id: wifiProc
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: { if (text) root.wifiEnabled = text.trim().includes("enabled") }
        }
    }

    // Persistent Process for Bluetooth
    Process {
        id: btProc
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector {
            onStreamFinished: { if (text) root.btEnabled = text.trim().includes("Powered: yes") }
        }
    }

    function updateStatus() {
        batProc.running = true
        wifiProc.running = true
        btProc.running = true
    }

    Timer { interval: 5000; running: true; repeat: true; onTriggered: updateStatus() }
    Component.onCompleted: updateStatus()
}
