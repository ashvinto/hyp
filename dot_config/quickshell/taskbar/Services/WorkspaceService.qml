pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var taskList: []
    property int activeId: 1

    function refresh() {
        updateProcess.running = true
    }

    Process {
        id: updateProcess
        command: ["sh", "-c", "hyprctl workspaces -j && echo '---' && hyprctl activeworkspace -j && echo '---' && hyprctl clients -j"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return
                var parts = text.split("---")
                try {
                    var active = JSON.parse(parts[1])
                    var clients = JSON.parse(parts[2])

                    root.activeId = active.id

                    // 1. Group unique icons by workspace
                    var wsGroups = {}
                    
                    for (var i = 0; i < clients.length; i++) {
                        var c = clients[i]
                        var wid = c.workspace.id
                        if (wid < 0) continue 

                        if (!wsGroups[wid]) wsGroups[wid] = []
                        
                        var cls = c.class.toLowerCase()
                        var icon = cls
                        if (cls.includes("firefox")) icon = "firefox"
                        else if (cls.includes("vivaldi")) icon = "vivaldi"
                        else if (cls.includes("code")) icon = "visual-studio-code"
                        else if (cls.includes("kitty")) icon = "kitty"
                        else if (cls.includes("foot")) icon = "foot"
                        else if (cls.includes("thunar")) icon = "system-file-manager"
                        else if (cls.includes("discord")) icon = "discord"
                        else if (cls.includes("spotify")) icon = "spotify"
                        else if (cls.includes("chrome")) icon = "google-chrome"
                        else if (cls.includes("zen")) icon = "zen-browser"
                        
                        if (wsGroups[wid].indexOf(icon) === -1) {
                            wsGroups[wid].push(icon)
                        }
                    }

                    // 2. Build flattened task list
                    var flatList = []
                    var occupiedWs = Object.keys(wsGroups).map(Number).sort((a,b) => a-b)
                    
                    // Add all occupied workspaces
                    for (var j = 0; j < occupiedWs.length; j++) {
                        var wId = occupiedWs[j]
                        var apps = wsGroups[wId]
                        
                        for (var k = 0; k < apps.length; k++) {
                            flatList.push({
                                "wsId": wId,
                                "icon": apps[k],
                                "isEmpty": false
                            })
                        }
                    }

                    // 3. Ensure active workspace is visible if empty
                    var activeExists = flatList.some(item => item.wsId === root.activeId)
                    if (!activeExists) {
                        flatList.push({
                            "wsId": root.activeId,
                            "icon": "",
                            "isEmpty": true
                        })
                    }

                    // Sort: Primary by WS ID, then icons alphabetically (optional but cleaner)
                    flatList.sort((a, b) => {
                        if (a.wsId !== b.wsId) return a.wsId - b.wsId
                        return a.icon.localeCompare(b.icon)
                    })

                    root.taskList = flatList

                } catch(e) {
                    console.error("[WorkspaceService] Parse error:", e)
                }
            }
        }
    }

    function goTo(id) {
        Quickshell.execDetached(["hyprctl", "dispatch", "workspace", id.toString()])
        refresh()
    }
}
