pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "."

Singleton {
    property var wallpapers: []
    property bool scanning: false

    function scan() {
        scanning = true
        scanProcess.running = true
    }

    Process {
        id: scanProcess
        command: ["find", AppConfig.wallpaperDir, "-type", "f", "(", "-iname", "*.jpg", "-o", "-iname", "*.png", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.webp", ")"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    wallpapers = text.trim().split("\n")
                } else {
                    wallpapers = []
                }
                scanning = false
            }
        }
    }
}