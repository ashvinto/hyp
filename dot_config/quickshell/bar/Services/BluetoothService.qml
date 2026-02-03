pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool powered: false
    property bool scanning: false
    property var devices: []
    property var connectedDevices: [] // List of MACs

    function togglePower() {
        Quickshell.execDetached(["sh", "-c", "echo '" + (powered ? "power off" : "power on") + "' | bluetoothctl"])
    }

    function scan() {
        if (scanning) {
            Quickshell.execDetached(["sh", "-c", "echo 'scan off' | bluetoothctl"])
            scanning = false
        } else {
            Quickshell.execDetached(["sh", "-c", "echo 'scan on' | bluetoothctl"])
            scanning = true
        }
        // Trigger an update shortly after
        scanTimer.restart()
    }

    function connect(mac) {
        Quickshell.execDetached(["sh", "-c", "echo 'connect " + mac + "' | bluetoothctl"])
    }

    function disconnect(mac) {
        Quickshell.execDetached(["sh", "-c", "echo 'disconnect " + mac + "' | bluetoothctl"])
    }

    function pair(mac) {
        Quickshell.execDetached(["sh", "-c", "echo 'pair " + mac + "' | bluetoothctl"])
    }

    function openManager() {
        Quickshell.execDetached(["blueman-manager"])
    }

    // Parse device list from output
    function parseDevices(output) {
        var list = []
        var lines = output.split("\n")
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line.startsWith("Device ") || line.startsWith("Controller ")) {
                var parts = line.split(" ")
                if (parts.length >= 3) {
                    var mac = parts[1]
                    var name = parts.slice(2).join(" ")

                    // Determine icon
                    var icon = "󰂯"
                    var n = name.toLowerCase()
                    if (n.includes("headphone") || n.includes("headset") || n.includes("buds")) icon = "󰋎"
                    else if (n.includes("keyboard")) icon = "󰥻"
                    else if (n.includes("mouse")) icon = "󰍽"
                    else if (n.includes("speaker") || n.includes("jbl")) icon = "󰓃"
                    else if (n.includes("phone")) icon = "󰏲"

                    var isConnected = false
                    for (var j = 0; j < root.connectedDevices.length; j++) {
                        if (root.connectedDevices[j] === mac) {
                            isConnected = true
                            break
                        }
                    }

                    list.push({
                        mac: mac,
                        name: name,
                        icon: icon,
                        connected: isConnected
                    })
                }
            }
        }
        // Sort: Connected first
        list.sort(function(a, b) { return (b.connected === true) - (a.connected === true) })
        root.devices = list
    }

    // Status & Connections Process
    Process {
        id: statusProc
        command: ["bash", "-c", "bluetoothctl show | grep Powered; bluetoothctl devices Connected"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.powered = text.includes("Powered: yes")
                
                // Note: scanning state is hard to track reliably via show, so we rely on user toggle + optimistic
                // But we can try to update it if we see it
                if (text.includes("Discovering: yes")) root.scanning = true
                
                var macs = []
                var lines = text.split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].trim().split(" ")
                    if (parts.length >= 2 && parts[0] === "Device") {
                        macs.push(parts[1])
                    }
                }
                root.connectedDevices = macs
            }
        }
    }

    // Devices Process
    Process {
        id: devicesProc
        command: ["bash", "-c", "bluetoothctl devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                parseDevices(text)
            }
        }
    }

    Timer {
        id: scanTimer
        interval: 500
        onTriggered: {
            statusProc.running = true
            devicesProc.running = true
        }
    }

    // Periodic Update
    Timer {
        interval: 3000; running: true; repeat: true
        onTriggered: {
            statusProc.running = true
            devicesProc.running = true
        }
    }

    Component.onCompleted: {
        statusProc.running = true
        devicesProc.running = true
    }
}