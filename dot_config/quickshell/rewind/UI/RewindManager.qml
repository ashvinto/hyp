import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../Common/Services" as Common
import "../Services" as Local

PanelWindow {
    id: root
    
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "rewind-utility"

    readonly property color cBg: (typeof Common.ThemeService !== "undefined" && Common.ThemeService.backgroundDark) ? Common.ThemeService.backgroundDark : "#11111b"
    readonly property color cSurface: (typeof Common.ThemeService !== "undefined" && Common.ThemeService.surface) ? Common.ThemeService.surface : "#1e1e2e"
    readonly property color cAccent: (typeof Common.ThemeService !== "undefined" && Common.ThemeService.accent) ? Common.ThemeService.accent : "#cba6f7"
    readonly property color cText: (typeof Common.ThemeService !== "undefined" && Common.ThemeService.text) ? Common.ThemeService.text : "#cdd6f4"
    readonly property color cDim: (typeof Common.ThemeService !== "undefined" && Common.ThemeService.text_dim) ? Common.ThemeService.text_dim : "#6c7086"
    readonly property color cError: "#f38ba8"

    Component.onCompleted: {
        console.log("[Rewind] UI Initialized")
        refreshData()
    }

    function refreshData() {
        console.log("[Rewind] Refreshing all data...")
        sessionLoader.running = true
        pacmanLoader.running = true
    }

    function saveCurrentSession() {
        console.log("[Rewind] Triggering session save...")
        Quickshell.execDetached(["bash", "/home/zoro/.config/hypr/scripts/session-manager.sh", "save"])
        refreshTimer.start()
    }
    Timer { id: refreshTimer; interval: 1000; onTriggered: sessionLoader.running = true }

    Rectangle {
        anchors.fill: parent; color: "#88000000"
        MouseArea { anchors.fill: parent; onClicked: Qt.quit() }
    }

    Rectangle {
        id: container
        anchors.centerIn: parent
        width: 1100; height: 750
        color: Qt.rgba(cBg.r, cBg.g, cBg.b, 0.95)
        radius: 32; border.color: Qt.rgba(1, 1, 1, 0.1); border.width: 1; clip: true

        layer.enabled: true
        layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 0.8; shadowOpacity: 0.5; shadowVerticalOffset: 12 }

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 40; spacing: 20

            // Header
            RowLayout {
                Layout.fillWidth: true; spacing: 15
                Text { text: "󰁯"; color: cAccent; font.pixelSize: 32; font.family: "Symbols Nerd Font" }
                Text { text: "REWIND HUB"; color: cText; font.bold: true; font.pixelSize: 22; font.letterSpacing: 2; Layout.fillWidth: true }
                
                Button {
                    text: bar.currentIndex === 0 ? "󰄬 SAVE SESSION" : "󰑐 REFRESH PACKAGES"
                    onClicked: bar.currentIndex === 0 ? saveCurrentSession() : pacmanLoader.running = true
                    background: Rectangle { color: parent.hovered ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.1) : "transparent"; radius: 10; border.color: cAccent; border.width: 1 }
                    contentItem: Text { text: parent.text; color: cAccent; font.bold: true; padding: 10; font.family: "Symbols Nerd Font" }
                }
                
                IconButton { text: "󰅖"; onClicked: Qt.quit(); iconColor: cError }
            }

            TabBar {
                id: bar; Layout.fillWidth: true; background: null
                TabButton { text: "󱊄 SESSIONS"; width: 180 }
                TabButton { text: "󰏖 PACKAGES"; width: 180 }
            }

            StackLayout {
                currentIndex: bar.currentIndex; Layout.fillWidth: true; Layout.fillHeight: true
                
                // --- SESSIONS TAB ---
                Item {
                    ListView {
                        id: sessionList; anchors.fill: parent; spacing: 12; clip: true; model: root.sessionModel
                        delegate: Rectangle {
                            width: sessionList.width - 10; height: 90; radius: 16
                            color: Qt.rgba(255,255,255,0.03); border.color: Qt.rgba(1,1,1,0.08); border.width: 1
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 20; spacing: 20
                                Rectangle {
                                    width: 50; height: 50; radius: 12; color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.1)
                                    Text { anchors.centerIn: parent; text: "󱊄"; color: cAccent; font.pixelSize: 28; font.family: "Symbols Nerd Font" }
                                }
                                ColumnLayout {
                                    spacing: 4; Layout.fillWidth: true
                                    Text { text: modelData.time; color: "white"; font.bold: true; font.pixelSize: 15 }
                                    Text { text: modelData.appCount + " Apps: " + modelData.apps; color: cDim; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }
                                }
                                Button {
                                    text: "RESTORE"
                                    onClicked: {
                                        console.log("[Rewind] Restoring session:", modelData.path)
                                        Quickshell.execDetached(["bash", "/home/zoro/.config/hypr/scripts/session-manager.sh", "restore", modelData.path])
                                    }
                                    background: Rectangle { color: parent.hovered ? cAccent : "transparent"; radius: 8; border.color: cAccent; border.width: 1 }
                                    contentItem: Text { text: parent.text; color: parent.hovered ? "#111" : cAccent; font.bold: true; padding: 8; font.pixelSize: 11 }
                                }
                            }
                        }
                    }
                    Text { anchors.centerIn: parent; text: "No sessions saved. Click Save above!"; color: cDim; visible: root.sessionModel.length === 0 }
                }

                // --- PACKAGES TAB ---
                Item {
                    ListView {
                        id: pkgList; anchors.fill: parent; spacing: 10; clip: true; 
                        model: root.pkgModel // ADDED MISSING MODEL BINDING
                        delegate: Rectangle {
                            width: pkgList.width - 10; height: 70; radius: 14
                            color: Qt.rgba(255,255,255,0.03); border.color: Qt.rgba(1,1,1,0.08); border.width: 1
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 15; spacing: 15
                                Text { 
                                    text: modelData.action === "installed" ? "󰏖" : (modelData.action === "removed" ? "󰆴" : "󰚀")
                                    color: modelData.action === "removed" ? cError : cAccent
                                    font.pixelSize: 22; font.family: "Symbols Nerd Font" 
                                }
                                ColumnLayout {
                                    spacing: 2; Layout.fillWidth: true
                                    Text { text: modelData.package; color: "white"; font.bold: true; font.pixelSize: 14 }
                                    Text { text: modelData.details; color: cDim; font.pixelSize: 10; elide: Text.ElideRight; Layout.fillWidth: true }
                                }
                                Text { text: modelData.time.split("T")[0]; color: cDim; font.pixelSize: 10 }
                            }
                        }
                    }
                    Text { anchors.centerIn: parent; text: "No recent system changes."; color: cDim; visible: root.pkgModel.length === 0 }
                }
            }
        }
    }
    
    // Components
    component TabButton: Button {
        contentItem: Text { text: parent.text; color: parent.checked ? cAccent : cDim; font.bold: parent.checked; font.pixelSize: 13; horizontalAlignment: Text.AlignHCenter }
        background: Rectangle { color: parent.checked ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.1) : "transparent"; radius: 10; border.color: parent.checked ? cAccent : "transparent"; border.width: 1 }
    }

    component IconButton: Rectangle {
        property string text: ""
        property color iconColor: cAccent
        signal clicked()
        width: 40; height: 40; radius: 12; color: Qt.rgba(255,255,255,0.05)
        Text { anchors.centerIn: parent; text: parent.text; color: parent.iconColor; font.pixelSize: 20; font.family: "Symbols Nerd Font" }
        MouseArea { anchors.fill: parent; hoverEnabled: true; onClicked: parent.clicked() }
    }

    property var pkgModel: []
    property var sessionModel: []
    
    Process {
        id: sessionLoader; command: ["bash", "/home/zoro/.config/hypr/scripts/session-manager.sh", "list"]
        stdout: StdioCollector { onStreamFinished: {
            if (text) { try { root.sessionModel = JSON.parse(text) } catch(e) { root.sessionModel = [] } }
        }}
    }
    
    Process {
        id: pacmanLoader; command: ["bash", "/home/zoro/.config/quickshell/rewind/scripts/pacman_history.sh"]
        stdout: StdioCollector { onStreamFinished: {
            if (text) { try { root.pkgModel = JSON.parse(text) } catch(e) { root.pkgModel = [] } }
        }}
    }
}
