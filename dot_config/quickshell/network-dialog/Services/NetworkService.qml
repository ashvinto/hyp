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

    function connectAdvanced(config) {
        notify("Connecting", "Configuring and connecting to " + config.ssid)
        
        // Use a more reliable way to build the command string
        // Quoting SSIDs and Passwords properly for the shell
        var ssid = config.ssid.replace(/'/g, "'\'\''")
        var pass = config.password.replace(/'/g, "'\'\''")
        var identity = (config.identity || "").replace(/'/g, "'\'\''")
        var iface = "$(nmcli -t -f TYPE,DEVICE device | grep '^wifi' | cut -d: -f2 | head -n1)"
        
        var cmd = "nmcli connection delete '" + ssid + "' || true; "
        cmd += "nmcli connection add type wifi con-name '" + ssid + "' ifname " + iface + " ssid '" + ssid + "' "
        
        cmd += "connection.autoconnect " + (config.autoConnect ? "yes " : "no ")
        
        if (config.metered !== "automatic") {
            cmd += "connection.metered " + (config.metered === "yes" ? "yes " : "no ")
        }

        if (config.method === "wpa") {
            cmd += "wifi-sec.key-mgmt wpa-psk wifi-sec.psk '" + pass + "' "
        } else if (config.method === "enterprise") {
            cmd += "802-11-wireless-security.key-mgmt wpa-eap "
            cmd += "802-1x.eap " + config.eapMethod.toLowerCase() + " "
            cmd += "802-1x.identity '" + identity + "' "
            cmd += "802-1x.password '" + pass + "' "
            
            if (config.eapMethod !== "TLS") {
                cmd += "802-1x.phase2-auth " + config.phase2.toLowerCase() + " "
            }
            
            if (config.caCert && config.caCert !== "") {
                cmd += "802-1x.ca-cert '" + config.caCert.replace(/'/g, "'\'\''") + "' "
            } else {
                // For many Enterprise networks, especially those without certificate validation,
                // we should not specify ca-cert at all, rather than setting it to 'none'
                // which causes errors. Only set system-ca-certs to no when no cert is provided.
                cmd += "802-1x.system-ca-certs no "
            }
        }

        if (config.ipMethod === "static") {
            cmd += "ipv4.method manual ipv4.addresses '" + config.staticIp + "' "
            if (config.gateway) cmd += "ipv4.gateway '" + config.gateway + "' "
            if (config.dns) cmd += "ipv4.dns '" + config.dns + "' "
        } else {
            cmd += "ipv4.method auto "
        }

        if (config.proxyMethod === "manual") {
            cmd += "proxy.method manual proxy.http-proxy '" + config.proxyUrl + "' "
        } else if (config.proxyMethod === "auto") {
            cmd += "proxy.method auto proxy.pac-url '" + config.proxyPac + "' "
        }

        cmd += " && nmcli connection up '" + ssid + "'"
        
        // Debug
        console.log("NM Command: " + cmd)
        
        Quickshell.execDetached(["sh", "-c", cmd])
        scanTimer.start()
    }

    // Compatibility wrappers
    function connect(ssid) { connectAdvanced({ ssid: ssid, method: "open", autoConnect: true, metered: "automatic", ipMethod: "dhcp" }) }
    function connectWithPassword(ssid, password) { connectAdvanced({ ssid: ssid, method: "wpa", password: password, autoConnect: true, metered: "automatic", ipMethod: "dhcp" }) }
    function connectEnterprise(ssid, identity, password) { connectAdvanced({ ssid: ssid, method: "enterprise", identity: identity, password: password, eapMethod: "PEAP", phase2: "MSCHAPV2", autoConnect: true, metered: "automatic", ipMethod: "dhcp" }) }

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