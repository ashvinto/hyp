import QtQuick
import Quickshell
import Quickshell.Io
import "./UI"

ShellRoot {
    id: root

    // Prevent multiple instances
    Process {
        id: instanceCheck
        command: ["sh", "-c", "pgrep -f 'qs -c emoji-picker' | wc -l"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (parseInt(text.trim()) > 1) {
                    Qt.quit()
                }
            }
        }
    }

    EmojiPanel { id: panel }
}