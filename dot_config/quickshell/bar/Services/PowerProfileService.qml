pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property string activeProfile: "balanced"
    property var profiles: ["performance", "balanced", "power-saver"]

    function refresh() {
        fetcher.running = true
    }

    function setProfile(name) {
        Quickshell.execDetached(["powerprofilesctl", "set", name])
        activeProfile = name
    }

    Process {
        id: fetcher
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    root.activeProfile = text.trim()
                }
            }
        }
    }

    Component.onCompleted: refresh()
    
    // Auto refresh every 30 seconds just in case
    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: refresh()
    }
}
