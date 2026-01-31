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

    Process { 
        id: activeWifiProc; 
        command: ["sh", "-c", "nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes' | cut -d: -f2"]; 
        stdout: StdioCollector { onStreamFinished: root.activeWifiSsid = text.trim() } 
    }

    function scan() {
        if (scanning) return
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
        Quickshell.execDetached(["nmcli", "device", "wifi", "connect", ssid])
        scan()
    }

    function connectWithPassword(ssid, password) {
        var cmd = "nmcli device wifi connect '" + ssid + "' password '" + password + "'";
        Quickshell.execDetached(["sh", "-c", cmd]);
        scan()
    }

    function connectEnterprise(ssid, identity, password) {
        var cmd = "IFACE=$(nmcli -t -f TYPE,DEVICE device | grep '^wifi' | cut -d: -f2 | head -n1); " +
                  "nmcli connection delete \"" + ssid + "\" || true; " +
                  "nmcli connection add type wifi con-name \"" + ssid + "\" ifname \"$IFACE\" ssid \"" + ssid + "\" -- " +
                  "802-11-wireless-security.key-mgmt wpa-eap " +
                  "802-1x.eap peap " +
                  "802-1x.phase2-auth mschapv2 " +
                  "802-1x.identity \"" + identity + "\" " +
                  "802-1x.password \"" + password + "\" " +
                  "802-1x.ca-cert \"\" " +
                  "802-1x.domain-suffix-match \"; " +
                  "nmcli connection up \"" + ssid + "\"";

        Quickshell.execDetached(["sh", "-c", cmd])
        scan()
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
                    for (var i = 0; i < lines.length; i++) {
                        var parts = lines[i].split(":")
                        if (parts.length >= 5 && parts[0] !== "") {
                            var ssid = parts[0]
                            if (!seen[ssid]) {
                                list.push({
                                    "ssid": ssid,
                                    "signal": parseInt(parts[1]),
                                    "bars": parts[2],
                                    "security": parts[3],
                                    "active": parts[4] === "yes"
                                })
                                seen[ssid] = true
                            }
                        }
                    }
                    list.sort(function(a, b) { return b.signal - a.signal })
                    root.networks = list
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