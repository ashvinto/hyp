pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int brightness: 0
    signal changed()

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
                if (text) {
                    let b = parseInt(text.trim()) || 0
                    if (b !== root.brightness) {
                        root.brightness = b
                        root.changed()
                    }
                }
            }
        }
    }

    Timer { interval: 500; running: true; repeat: true; onTriggered: update() }
    Component.onCompleted: update()
}
