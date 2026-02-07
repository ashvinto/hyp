pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var history: []
    property bool loading: false

    function refresh() {
        if (loading) return
        loading = true
        fetchProcess.running = true
    }

    Process {
        id: fetchProcess
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    var lines = text.trim().split("\n")
                    var newHistory = []
                    for (var i = 0; i < lines.length; i++) {
                        var line = lines[i]
                        if (line.trim() === "") continue
                        newHistory.push({
                            "full": line,
                            "preview": line.substring(line.indexOf("\t") + 1).trim() || line
                        })
                    }
                    history = newHistory
                } else {
                    history = []
                }
                loading = false
            }
        }
    }

    function select(fullLine) {
        console.log("[Clipboard] Selection triggered for:", fullLine)
        
        // Manual shell escape: replace ' with '\'' and wrap in ''
        var escaped = fullLine.replace(/'/g, "'\\''")
        var cmd = "printf '%s' '" + escaped + "' | cliphist decode | wl-copy"
        
        Quickshell.execDetached(["sh", "-c", cmd])
    }
    
    function deleteItem(fullLine, index) {
        console.log("[Clipboard] Deleting item:", fullLine)
        
        // Pass the line as a single argument to printf to ensure exact match
        var cmd = ["sh", "-c", "printf '%s' \"$1\" | cliphist delete", "--", fullLine]
        
        Quickshell.execDetached(cmd)
        
        // Remove from local model immediately
        var newHistory = []
        for (var i = 0; i < history.length; i++) {
            if (i !== index) newHistory.push(history[i])
        }
        history = newHistory
    }
    
    function clear() {
        Quickshell.execDetached(["cliphist", "wipe"])
        history = []
    }
}