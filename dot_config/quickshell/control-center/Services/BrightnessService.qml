pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int brightness: 0

    function update() {
        brightProc.running = true
    }

    function setBrightness(v) {
        Quickshell.execDetached(["brightnessctl", "s", v + "%"])
        brightness = v
    }

    Process {
        id: brightProc
        command: ["sh", "-c", "brightnessctl -m | cut -d',' -f4 | tr -d '%'"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) root.brightness = parseInt(text.trim()) || 0
            }
        }
    }

    Timer { interval: 5000; running: true; repeat: true; onTriggered: update() }
    Component.onCompleted: update()
}
