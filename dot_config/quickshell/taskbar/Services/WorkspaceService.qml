pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var workspaces: []
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
                    var wsListRaw = JSON.parse(parts[0])
                    var active = JSON.parse(parts[1])
                    var clients = JSON.parse(parts[2])

                    root.activeId = active.id

                    // Map workspace ID -> Array of Icons
                    var wsApps = {}
                    
                    for (var i = 0; i < clients.length; i++) {
                        var c = clients[i]
                        var wid = c.workspace.id
                        if (wid < 0) continue // Skip special workspaces

                        if (!wsApps[wid]) wsApps[wid] = []
                        
                        var cls = c.class.toLowerCase()
                        var icon = cls
                        if (cls.includes("firefox")) icon = "firefox"
                        else if (cls.includes("vivaldi")) icon = "vivaldi"
                        else if (cls.includes("code")) icon = "visual-studio-code"
                        else if (cls.includes("kitty")) icon = "kitty"
                        else if (cls.includes("thunar")) icon = "system-file-manager"
                        else if (cls.includes("discord")) icon = "discord"
                        
                        // Avoid duplicates in the same workspace group
                        if (wsApps[wid].indexOf(icon) === -1) {
                            wsApps[wid].push(icon)
                        }
                    }

                    // Build the final list: 
                    // Include workspaces that exist in hyprctl OR are the active one
                    var finalWorkspaces = []
                    
                    // Helper to check if ID is in list
                    var existingIds = []
                    
                    // 1. Add occupied workspaces from client list
                    for (var id in wsApps) {
                        var numId = parseInt(id)
                        finalWorkspaces.push({
                            "id": numId,
                            "apps": wsApps[id]
                        })
                        existingIds.push(numId)
                    }

                    // 2. Ensure active workspace is present even if empty
                    if (existingIds.indexOf(root.activeId) === -1) {
                        finalWorkspaces.push({
                            "id": root.activeId,
                            "apps": []
                        })
                    }

                    // 3. Sort by ID
                    finalWorkspaces.sort((a, b) => a.id - b.id)
                    root.workspaces = finalWorkspaces

                } catch(e) {}
            }
        }
    }

    function goTo(id) {
        Quickshell.execDetached(["hyprctl", "dispatch", "workspace", id.toString()])
        refresh()
    }
}
