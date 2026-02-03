pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var networks: []
    property var connections: []
    property bool scanning: false
    
    property bool wifiEnabled: true
    property bool networkingEnabled: true
    
    property string ethernetStatus: "Disconnected"
    property string activeWifiSsid: ""

    function refreshStatus() {
        wifiStatusProc.running = true
        netStatusProc.running = true
        connectionsProc.running = true
        ethStatusProc.running = true
        activeWifiProc.running = true
    }

    function notify(title, message) {
        Quickshell.execDetached(["notify-send", "-a", "Network Manager", title, message])
    }

    Process { 
        id: activeWifiProc; 
        command: ["sh", "-c", "nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes' | cut -d: -f2"]; 
        stdout: StdioCollector { onStreamFinished: root.activeWifiSsid = text.trim() } 
    }

    property var lastScanTime: 0
    property int scanCooldown: 15000 // 15 seconds

    function scan() {
        var now = new Date().getTime()
        if (scanning) return
        
        // Prevent spamming scans which kills connections on some drivers
        if (now - lastScanTime < scanCooldown) {
            console.log("Skipping scan: Cooldown active")
            return
        }
        
        lastScanTime = now
        scanning = true
        scanProc.running = true
        refreshStatus()
    }

    function toggleWifi() {
        var cmd = wifiEnabled ? "off" : "on"
        Quickshell.execDetached(["nmcli", "radio", "wifi", cmd])
        wifiEnabled = !wifiEnabled
    }

    function toggleNetworking() {
        var cmd = networkingEnabled ? "off" : "on"
        Quickshell.execDetached(["nmcli", "networking", cmd])
        networkingEnabled = !networkingEnabled
    }

    function disconnect() {
        Quickshell.execDetached(["sh", "-c", "nmcli device disconnect $(nmcli -t -f TYPE,DEVICE device | grep '^wifi' | cut -d: -f2)"])
        scan()
    }

    function connect(ssid) {
        notify("Connecting", "Attempting to connect to " + ssid)
        Quickshell.execDetached(["nmcli", "device", "wifi", "connect", ssid])
        scanTimer.start()
    }

    function connectWithPassword(ssid, password) {
        notify("Connecting", "Attempting to connect to " + ssid)
        var cmd = "nmcli connection delete \"" + ssid.replace(/"/g, '\\"') + "\" || true; " + 
                  "nmcli device wifi connect \"" + ssid.replace(/"/g, '\\"') + "\" password \"" + password.replace(/"/g, '\\"') + "\"";
        Quickshell.execDetached(["sh", "-c", cmd])
        scanTimer.start()
    }

    function connectEnterprise(ssid, identity, password) {
        notify("Connecting", "Attempting to connect to " + ssid + " (Enterprise)")
        var deleteCmd = "nmcli connection delete \"" + ssid.replace(/"/g, '\\"') + "\" || true; "
        var addCmd = "IFACE=$(nmcli -t -f TYPE,DEVICE device | grep '^wifi' | cut -d: -f2 | head -n1); " + 
                     "nmcli connection add type wifi con-name \"" + ssid.replace(/"/g, '\\"') + "\" ifname \"$IFACE\" ssid \"" + ssid.replace(/"/g, '\\"') + "\" -- " + 
                     "802-11-wireless-security.key-mgmt wpa-eap " + 
                     "802-1x.eap peap " + 
                     "802-1x.phase2-auth mschapv2 " + 
                     "802-1x.identity \"" + identity.replace(/"/g, '\\"') + "\" " + 
                     "802-1x.password \"" + password.replace(/"/g, '\\"') + "\" " + 
                     "802-1x.ca-cert \"\" " + 
                     "802-1x.domain-suffix-match \"\"; " + 
                     "nmcli connection up \"" + ssid.replace(/"/g, '\\"') + "\""
        Quickshell.execDetached(["sh", "-c", deleteCmd + addCmd])
        scanTimer.start()
    }

    Timer {
        id: scanTimer
        interval: 2000
        onTriggered: scan()
    }

    function openEditor() {
        Quickshell.execDetached(["nm-connection-editor"])
    }

    Process {
        id: scanProc
        command: ["nmcli", "-t", "-f", "SSID,SIGNAL,BARS,SECURITY,ACTIVE", "dev", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    var lines = text.trim().split("\n")
                    var list = []
                    var seen = {}
                    var activeSsid = ""
                    for (var i = 0; i < lines.length; i++) {
                        var parts = lines[i].split(":")
                        if (parts.length >= 5 && parts[0] !== "") {
                            var ssid = parts[0]
                            var active = parts[4] === "yes"
                            if (active) activeSsid = ssid
                            if (!seen[ssid]) {
                                list.push({
                                    "ssid": ssid,
                                    "signal": parseInt(parts[1]),
                                    "bars": parts[2],
                                    "security": parts[3],
                                    "active": active
                                })
                                seen[ssid] = true
                            }
                        }
                    }
                    list.sort(function(a, b) { return b.signal - a.signal })
                    root.networks = list
                    if (activeSsid !== "") root.activeWifiSsid = activeSsid
                }
                scanning = false
            }
        }
    }

    Process {
        id: connectionsProc
        command: ["nmcli", "-t", "-f", "NAME,TYPE,DEVICE,ACTIVE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    var lines = text.trim().split("\n")
                    var list = []
                    for (var i = 0; i < lines.length; i++) {
                        var parts = lines[i].split(":")
                        if (parts.length >= 4) {
                            list.push({
                                "name": parts[0],
                                "type": parts[1],
                                "device": parts[2],
                                "active": parts[3] === "yes"
                            })
                        }
                    }
                    connections = list
                }
            }
        }
    }

    Process { id: wifiStatusProc; command: ["nmcli", "radio", "wifi"]; stdout: StdioCollector { onStreamFinished: root.wifiEnabled = text.trim() === "enabled" } }
    Process { id: netStatusProc; command: ["nmcli", "networking", "connectivity"]; stdout: StdioCollector { onStreamFinished: root.networkingEnabled = text.trim() !== "none" } }
    Process { 
        id: ethStatusProc; 
        command: ["sh", "-c", "nmcli -t -f TYPE,STATE device | grep '^ethernet:' | head -n1 | cut -d: -f2"]; 
        stdout: StdioCollector { 
            onStreamFinished: {
                var status = text.trim();
                if (status === "connected") root.ethernetStatus = "Connected"
                else root.ethernetStatus = "Disconnected"
            }
        } 
    }

    Component.onCompleted: refreshStatus()
}
