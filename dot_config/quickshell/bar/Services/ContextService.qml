pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string activeClass: ""
    property string activeTitle: ""
    property string gitBranch: ""
    property string cwd: ""

    function update() {
        activeWindowProc.running = true
    }

    Process {
        id: activeWindowProc
        command: ["hyprctl", "activewindow", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    try {
                        var data = JSON.parse(text)
                        root.activeClass = data.class || ""
                        root.activeTitle = data.title || ""
                        
                        if (root.activeClass === "foot") {
                            updateCwd()
                        } else if (root.activeClass === "VSCodium" || root.activeClass === "Cursor") {
                            updateGit()
                        } else {
                            root.gitBranch = ""
                            root.cwd = ""
                        }
                    } catch(e) {}
                }
            }
        }
    }

    function updateCwd() {
        cwdProc.running = true
    }

    Process {
        id: cwdProc
        command: ["sh", "-c", "ls -l /proc/$(hyprctl activewindow -j | jq -r '.pid')/cwd | awk '{print $NF}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) root.cwd = text.trim().replace(Quickshell.env("HOME"), "~")
            }
        }
    }

    function updateGit() {
        gitProc.running = true
    }

    Process {
        id: gitProc
        // Try to find git branch if title contains a path or we can guess project root
        // This is a bit complex for a generic script, we'll start by checking the title
        command: ["sh", "-c", "echo $activeTitle | grep -oP '(?<=\().*(?=\))' | head -1"] // Many editors show branch in title
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) root.gitBranch = text.trim()
            }
        }
    }

    // Refresh every 2 seconds
    Timer {
        interval: 2000; running: true; repeat: true
        onTriggered: update()
    }

    Component.onCompleted: update()
}
