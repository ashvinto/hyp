pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property string user: Quickshell.env("USER") || "User"
    readonly property string greeting: {
        var hour = new Date().getHours()
        if (hour < 12) return "Good Morning"
        if (hour < 18) return "Good Afternoon"
        return "Good Evening"
    }

    property string uptime: "..."
    property string osAge: "..."

    function updateStats() {
        statsProcess.running = true
    }

    Process {
        id: statsProcess
        // 1. Get uptime (pretty)
        // 2. Get OS install date (using /etc/hostname or root filesystem creation)
        command: ["sh", "-c", `
            uptime -p | sed 's/up //'; 
            echo "---";
            if [ -f /var/log/pacman.log ]; then 
                head -n1 /var/log/pacman.log | cut -d'[' -f2 | cut -d']' -f1 | cut -d' ' -f1;
            else 
                ls -lct /etc | tail -1 | awk '{print $6, $7, $8}'; 
            fi
        `]
        
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return
                var parts = text.trim().split("---")
                root.uptime = parts[0].trim()
                
                // Format Install Date to Age
                var installDateStr = parts[1].trim()
                if (installDateStr) {
                    var installDate = new Date(installDateStr)
                    var diff = new Date() - installDate
                    var days = Math.floor(diff / (1000 * 60 * 60 * 24))
                    root.osAge = days + " days"
                }
            }
        }
    }

    Component.onCompleted: updateStats()
    
    // Refresh uptime every minute
    Timer {
        interval: 60000; running: true; repeat: true
        onTriggered: updateStats()
    }
}