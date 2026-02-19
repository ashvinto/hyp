import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    // Process that runs the Electron app
    Process {
        id: aiProc
        command: ["bash", "-c", "cd /home/zoro/.config/quickshell/ai/zero-ai && npm start"]
        running: true
        
        // When the app closes (exit code received), quit Quickshell
        onExited: Qt.quit()
    }

    // Ensure we kill the app if Quickshell is killed (Ctrl+C)
    Component.onDestruction: {
        if (aiProc.running) {
            aiProc.terminate()
        }
    }
}