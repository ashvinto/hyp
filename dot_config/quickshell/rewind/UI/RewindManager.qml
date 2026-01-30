import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../Services" as Services

PanelWindow {
    id: root
    
    anchors.top: true; anchors.bottom: true; anchors.left: true; anchors.right: true
    color: "transparent"
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "rewind-utility"

    // Theme Colors (Standalone)
    readonly property color cBg: Services.ThemeService.background
    readonly property color cSurface: Services.ThemeService.surface
    readonly property color cAccent: Services.ThemeService.accent
    readonly property color cText: Services.ThemeService.text
    readonly property color cDim: Services.ThemeService.text_dim
    readonly property color cError: Services.ThemeService.error || "#ff4d4d"
    readonly property color cSuccess: Services.ThemeService.success || "#4dff4d"

    Component.onCompleted: {
        // Start the monitor if not running
        Quickshell.execDetached(["sh", "-c", "pgrep -f fs_monitor.py || python3 " + Quickshell.env("HOME") + "/.config/quickshell/rewind/scripts/fs_monitor.py &"])
        refreshData()
    }

    function refreshData() {
        fsLoader.running = true
        pacmanLoader.running = true
    }

    Rectangle {
        anchors.fill: parent
        color: "#66000000"
        MouseArea { anchors.fill: parent; onClicked: Qt.quit() }
        z: -1
    }

    Rectangle {
        anchors.centerIn: parent
        width: 1000
        height: 750
        color: Qt.rgba(cBg.r, cBg.g, cBg.b, 0.95)
        radius: 24
        border.color: Qt.rgba(1, 1, 1, 0.1)
        border.width: 1
        clip: true

        MultiEffect {
            anchors.fill: parent; source: parent; blurEnabled: true; blur: 1.0; z: -1
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 30
            spacing: 20

            // Header
            RowLayout {
                Layout.fillWidth: true
                Text { 
                    text: "⏪"; color: cAccent; font.pixelSize: 24
                }
                Text { 
                    text: "Rewind History"; color: cText; font.bold: true; font.pixelSize: 20; Layout.fillWidth: true 
                }
                
                Button {
                    text: "🔄 Refresh"
                    onClicked: refreshData()
                    background: Rectangle { color: "transparent"; border.color: cDim; radius: 8; border.width: 1 }
                    contentItem: Text { text: parent.text; color: cDim; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.bold: true; padding: 10 }
                }

                Button {
                    text: "Close"
                    onClicked: Qt.quit()
                    background: Rectangle { color: cSurface; radius: 8 }
                    contentItem: Text { text: parent.text; color: cText; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.bold: true; padding: 10 }
                }
            }

            TabBar {
                id: bar
                Layout.fillWidth: true
                background: Rectangle { color: "transparent" }
                
                TabButton {
                    text: "📂 File Monitor"
                    width: implicitWidth + 40
                    contentItem: Text { 
                        text: parent.text
                        color: parent.checked ? cAccent : cDim
                        font.bold: parent.checked
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 14
                    }
                    background: Rectangle { 
                        color: parent.checked ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.1) : "transparent"
                        radius: 8
                    }
                }
                
                TabButton {
                    text: "📦 System Changes"
                    width: implicitWidth + 40
                    contentItem: Text { 
                        text: parent.text
                        color: parent.checked ? cAccent : cDim
                        font.bold: parent.checked
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 14
                    }
                    background: Rectangle { 
                        color: parent.checked ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.1) : "transparent"
                        radius: 8
                    }
                }
            }

            StackLayout {
                currentIndex: bar.currentIndex
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                // --- FILE MONITOR TAB ---
                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 10

                        ListView {
                            id: fsList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 8
                            model: root.fsModel
                            
                            ScrollBar.vertical: ScrollBar {
                                active: true
                                policy: ScrollBar.AsNeeded
                            }

                            delegate: Rectangle {
                                width: fsList.width - 15
                                height: 70
                                color: cSurface
                                radius: 12
                                border.color: modelData.type === "DELETE" ? Qt.rgba(cError.r, cError.g, cError.b, 0.3) : "transparent"
                                border.width: 1
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 15
                                    spacing: 15
                                    
                                    Text { 
                                        text: modelData.type === "DELETE" ? "🗑️" : (modelData.type === "CREATE" ? "✨" : "✏️")
                                        font.pixelSize: 24
                                    }
                                    
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text { 
                                            text: modelData.path.split('/').pop()
                                            color: modelData.type === "DELETE" ? cError : cText
                                            font.bold: true 
                                            font.pixelSize: 15
                                        }
                                        Text { 
                                            text: modelData.path
                                            color: cDim
                                            font.pixelSize: 12
                                            elide: Text.ElideMiddle 
                                            Layout.fillWidth: true
                                        }
                                    }

                                    Text { 
                                        text: modelData.time.replace("T", " ").split(".")[0]
                                        color: cDim
                                        font.pixelSize: 11
                                    }
                                }
                            }
                        }
                    }
                }

                // --- SYSTEM PACKAGES TAB ---
                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 10
                        
                        ListView {
                            id: pkgList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            model: root.pkgModel
                            spacing: 8
                            
                            ScrollBar.vertical: ScrollBar {
                                active: true
                                policy: ScrollBar.AsNeeded
                            }

                            delegate: Rectangle {
                                width: pkgList.width - 15
                                height: 65
                                color: cSurface
                                radius: 12
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 15
                                    spacing: 15
                                    
                                    Text { 
                                        text: modelData.action === "installed" ? "📥" : (modelData.action === "upgraded" ? "⬆️" : "❌")
                                        font.pixelSize: 20
                                    }
                                    
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text { text: modelData.package; color: cText; font.bold: true; font.pixelSize: 15 }
                                        Text { text: modelData.details; color: cDim; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true }
                                    }
                                    
                                    Text {
                                        text: modelData.time
                                        color: cDim
                                        font.pixelSize: 11
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    property var fsModel: []
    property var pkgModel: []
    
    Process {
        id: fsLoader
        command: ["cat", Quickshell.env("HOME") + "/.cache/fs_history.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    try {
                        root.fsModel = JSON.parse(text)
                    } catch (e) { root.fsModel = [] }
                }
            }
        }
    }
    
    Process {
        id: pacmanLoader
        command: ["sh", Quickshell.env("HOME") + "/.config/quickshell/rewind/scripts/pacman_history.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    try {
                        root.pkgModel = JSON.parse(text)
                    } catch (e) { root.pkgModel = [] }
                }
            }
        }
    }
}
