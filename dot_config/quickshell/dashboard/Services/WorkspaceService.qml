pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var workspaces: []
    property int activeId: 1

    function update() {
        updateProcess.running = true
    }

    Process {
        id: updateProcess
        command: ["sh", "-c", "hyprctl workspaces -j && echo '---' && hyprctl activeworkspace -j"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return
                var parts = text.split("---")
                try {
                    var all = JSON.parse(parts[0])
                    var active = JSON.parse(parts[1])
                    root.activeId = active.id
                    // Sort by ID
                    all.sort((a, b) => a.id - b.id)
                    root.workspaces = all
                } catch(e) {}
            }
        }
    }

    function goTo(id) {
        Quickshell.execDetached(["hyprctl", "dispatch", "workspace", id.toString()])
        update()
    }
}
