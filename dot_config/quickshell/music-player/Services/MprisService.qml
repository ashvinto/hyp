pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string title: "No Media"
    property string artist: ""
    property string artUrl: ""
    property string status: "Stopped"
    property real position: 0
    property real length: 0
    property bool hasPlayer: false

    property string playerName: ""

    function togglePlay() { 
        var p = root.playerName || ""
        Quickshell.execDetached(["sh", "-c", "playerctl " + (p ? "-p " + p : "") + " play-pause"]) 
    }
    function next() { 
        var p = root.playerName || ""
        Quickshell.execDetached(["sh", "-c", "playerctl " + (p ? "-p " + p : "") + " next"]) 
    }
    function prev() { 
        var p = root.playerName || ""
        Quickshell.execDetached(["sh", "-c", "playerctl " + (p ? "-p " + p : "") + " previous"]) 
    }
    function seek(seconds) { 
        var p = root.playerName || ""
        Quickshell.execDetached(["sh", "-c", "playerctl " + (p ? "-p " + p : "") + " position " + String(seconds)]) 
    }

    // Unified poller
    Process {
        id: poller
        // Output format: PlayerName | Status | Title | Artist | ArtUrl | Length | Position
        command: ["sh", "-c", "
            players=$(playerctl -l)
            if [ -z \"$players\" ]; then echo 'NoPlayer'; exit; fi
            
            chosen=\"\"
            first=$(echo \"$players\" | head -n1)
            
            for p in $players; do
                st=$(playerctl -p \"$p\" status 2>/dev/null)
                if [ \"$st\" = \"Playing\" ]; then
                    chosen=\"$p\"
                    break
                fi
            done
            
            if [ -z \"$chosen\" ]; then chosen=\"$first\"; fi
            
            echo -n \"$chosen|||\"
            echo -n \"$(playerctl -p \"$chosen\" status)|||\"
            echo -n \"$(playerctl -p \"$chosen\" metadata title)|||\"
            echo -n \"$(playerctl -p \"$chosen\" metadata artist)|||\"
            echo -n \"$(playerctl -p \"$chosen\" metadata mpris:artUrl)|||\"
            echo -n \"$(playerctl -p \"$chosen\" metadata mpris:length)|||\"
            echo -n \"$(playerctl -p \"$chosen\" position)\"
        "]
        
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim() === "NoPlayer") {
                    root.hasPlayer = false
                    root.title = "No Media"
                    root.artist = ""
                    root.status = "Stopped"
                    return
                }

                root.hasPlayer = true
                var parts = text.split("|||")
                if (parts.length >= 7) {
                    root.playerName = parts[0].trim()
                    root.status = parts[1].trim()
                    root.title = parts[2].trim()
                    root.artist = parts[3].trim()
                    root.artUrl = parts[4].trim()
                    // Length is usually in microseconds, convert to seconds
                    var len = parseFloat(parts[5])
                    if (!isNaN(len)) root.length = len / 1000000
                    
                    var pos = parseFloat(parts[6])
                    if (!isNaN(pos)) root.position = pos
                }
            }
        }
    }

    Timer {
        id: tickTimer
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            if (root.status === "Playing") {
                root.position += 0.1
                // Clamp to length
                if (root.length > 0 && root.position > root.length) root.position = root.length
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: poller.running = true
    }
    
    Component.onCompleted: poller.running = true
}
