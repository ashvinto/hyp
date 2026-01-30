pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int volume: 0
    property bool muted: false
    
    signal changed()

    function update() {
        volProc.running = true
        muteProc.running = true
    }

    function setVolume(v) {
        Quickshell.execDetached(["pactl", "set-sink-volume", "@DEFAULT_SINK@", v + "%"])
        volume = v
    }

    function toggleMute() {
        Quickshell.execDetached(["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"])
        muted = !muted
    }

    Process {
        id: volProc
        command: ["sh", "-c", "pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\\d+%' | head -1 | tr -d '%'"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    let v = parseInt(text.trim()) || 0
                    if (v !== root.volume) {
                        root.volume = v
                        root.changed()
                    }
                }
            }
        }
    }

    Process {
        id: muteProc
        command: ["sh", "-c", "pactl get-sink-mute @DEFAULT_SINK@ | grep -q 'yes' && echo 1 || echo 0"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    let m = text.trim() === "1"
                    if (m !== root.muted) {
                        root.muted = m
                        root.changed()
                    }
                }
            }
        }
    }

    Timer { interval: 500; running: true; repeat: true; onTriggered: update() }
    Component.onCompleted: update()
}
