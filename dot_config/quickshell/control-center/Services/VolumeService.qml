pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int volume: 0
    property bool muted: false

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
                if (text) root.volume = parseInt(text.trim()) || 0
            }
        }
    }

    Process {
        id: muteProc
        command: ["sh", "-c", "pactl get-sink-mute @DEFAULT_SINK@ | grep -q 'yes' && echo 1 || echo 0"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) root.muted = text.trim() === "1"
            }
        }
    }

    Timer { interval: 2000; running: true; repeat: true; onTriggered: update() }
    Component.onCompleted: update()
}
