pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var networks: []
    property bool scanning: false

    function scan() {
        if (scanning) return
        scanning = true
        scanProc.running = true
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
                    networks = list
                }
                scanning = false
            }
        }
    }

    function connect(ssid) {
        Quickshell.execDetached(["nmcli", "device", "wifi", "connect", ssid])
        scan()
    }
}
