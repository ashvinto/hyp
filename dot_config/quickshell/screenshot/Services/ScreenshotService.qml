pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    
    // UI State
    property string activeMode: Quickshell.env("QS_SCREENSHOT_MODE") || "panel"
    
    // Options
    property int delay: 0

    function capture(mode) {
        if (mode === "freeze") {
            startFreeze()
            return
        }
        activeMode = "none"
        executeCapture(mode)
    }

    function startFreeze() {
        activeMode = "none" 
        var cmd = "grim /tmp/qs_freeze.png"
        var proc = Qt.createQmlObject('import Quickshell.Io; Process { command: ["sh", "-c", "' + cmd + '"] }', root, "freeze_proc")
        proc.exited.connect(function(code) {
            if (code === 0) activeMode = "overlay"
            else Qt.quit()
            proc.destroy()
        })
        proc.running = true
    }

    function processCrop(x, y, w, h) {
        var geom = w + "x" + h + "+" + x + "+" + y
        var filename = "/tmp/qs_screenshot_edit.png"
        var cmd = "magick /tmp/qs_freeze.png -crop " + geom + " " + filename + " && swappy -f " + filename
        
        var proc = Qt.createQmlObject('import Quickshell.Io; Process { command: ["sh", "-c", "' + cmd + '"] }', root, "crop_proc")
        proc.running = true
        // Close Quickshell immediately as swappy takes over
        Qt.quit()
    }

    function executeCapture(mode) {
        var filename = "/tmp/qs_screenshot_edit.png"
        var cmd = ""
        if (delay > 0) cmd += "sleep " + delay + "; "
        
        if (mode === "fullscreen") cmd += "grim " + filename
        else if (mode === "region" || mode === "window") cmd += "grim -g \"$(slurp)\" " + filename

        cmd += " && swappy -f " + filename

        var proc = Qt.createQmlObject('import Quickshell.Io; Process { command: ["sh", "-c", "' + cmd + '"] }', root, "capture_proc")
        proc.running = true
        // Close Quickshell immediately as swappy takes over
        Qt.quit()
    }
}