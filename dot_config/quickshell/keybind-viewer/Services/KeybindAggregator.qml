pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var allBinds: []
    property bool loading: false

    function refresh() {
        if (loading) return
        loading = true
        fetcher.running = true
    }

    Process {
        id: fetcher
        command: ["python3", "/home/zoro/.config/quickshell/keybind-viewer/Services/fetch_binds.py"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    try {
                        root.allBinds = JSON.parse(text)
                        console.log("[KeybindAggregator] Parsed " + root.allBinds.length + " bindings")
                    } catch(e) {
                        console.log("Error parsing JSON from python script:", e)
                    }
                }
                loading = false
            }
        }
        
        stderr: StdioCollector {
            onStreamFinished: {
                if (text) console.error("Python stderr:", text)
            }
        }
    }
}
