import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../Services" as Services

PanelWindow {
    id: root

    anchors.top: true; anchors.bottom: true; anchors.left: true; anchors.right: true
    width: 1000
    height: 750

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "keybind-viewer"

    color: "transparent"

    readonly property color cBg: Services.ThemeService.background
    readonly property color cSurface: Services.ThemeService.surface
    readonly property color cAccent: Services.ThemeService.accent
    readonly property color cText: Services.ThemeService.text
    readonly property color cDim: Services.ThemeService.text_dim

    Component.onCompleted: {
        Services.KeybindAggregator.refresh()
        searchInput.forceActiveFocus()
    }

    property string filterText: ""
    property string selectedSource: "All"
    
    property var filteredBinds: {
        var list = Services.KeybindAggregator.allBinds
        var res = list
        
        if (selectedSource !== "All") {
            res = res.filter(b => b.source === selectedSource)
        }
        
        if (filterText !== "") {
            var lower = filterText.toLowerCase()
            res = res.filter(b => 
                b.keys.toLowerCase().includes(lower) || 
                b.action.toLowerCase().includes(lower) ||
                b.source.toLowerCase().includes(lower)
            )
        }
        return res
    }

    Rectangle {
        anchors.fill: parent
        color: "#66000000"
        MouseArea { anchors.fill: parent; onClicked: Qt.quit() }
        z: -1
    }

    Rectangle {
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
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
                spacing: 15
                
                Text { text: ""; color: cAccent; font.pixelSize: 28; font.family: "Symbols Nerd Font" }
                
                ColumnLayout {
                    spacing: 0
                    Text { text: "Keybinding Viewer"; color: cText; font.bold: true; font.pixelSize: 20 }
                    Text { text: root.filteredBinds.length + " bindings found"; color: cDim; font.pixelSize: 12 }
                }
                
                Item { Layout.fillWidth: true }
                
                // Source Filter
                RowLayout {
                    spacing: 8
                    Repeater {
                        model: ["All", "Hyprland", "Neovim", "LazyVim"]
                        delegate: Rectangle {
                            width: 80; height: 32; radius: 8
                            color: root.selectedSource === modelData ? cAccent : cSurface
                            Text { 
                                anchors.centerIn: parent; text: modelData
                                color: root.selectedSource === modelData ? cBg : cText
                                font.bold: true; font.pixelSize: 12
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.selectedSource = modelData
                            }
                        }
                    }
                }
            }

            // Search Bar
            Rectangle {
                Layout.fillWidth: true
                height: 50
                color: cSurface
                radius: 12
                border.color: searchInput.activeFocus ? cAccent : "transparent"
                border.width: 2
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 15; spacing: 10
                    Text { text: ""; color: cDim; font.family: "Symbols Nerd Font" }
                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        font.pixelSize: 14; color: cText; clip: true
                        onTextChanged: root.filterText = text
                        Keys.onEscapePressed: Qt.quit()
                    }
                }
            }

            // List Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Text { text: "SOURCE"; color: cDim; font.bold: true; font.pixelSize: 11; Layout.preferredWidth: 80 }
                Text { text: "SHORTCUT"; color: cDim; font.bold: true; font.pixelSize: 11; Layout.preferredWidth: 150 }
                Text { text: "ACTION / COMMAND"; color: cDim; font.bold: true; font.pixelSize: 11; Layout.fillWidth: true }
            }

            // Bindings List
            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: root.filteredBinds
                spacing: 6

                delegate: Rectangle {
                    width: list.width
                    height: 40
                    color: cSurface
                    radius: 8
                    border.color: Qt.rgba(1, 1, 1, 0.05)
                    border.width: 1
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 15; anchors.rightMargin: 15
                        spacing: 15
                        
                        // Source Badge
                        Rectangle {
                            Layout.preferredWidth: 70; height: 22; radius: 6
                            color: modelData.source === "Hyprland" ? "#89b4fa" : (modelData.source === "LazyVim" ? "#fab387" : "#a6e3a1")
                            Text {
                                anchors.centerIn: parent
                                text: modelData.source
                                color: "#11111b"; font.bold: true; font.pixelSize: 10
                            }
                        }
                        
                        // Key
                        Rectangle {
                            Layout.preferredWidth: 150; height: 26; radius: 6
                            color: Qt.rgba(1, 1, 1, 0.1)
                            Text {
                                anchors.centerIn: parent; width: parent.width - 10
                                text: modelData.keys
                                color: cAccent; font.bold: true; font.pixelSize: 12
                                elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                            }
                        }
                        
                        // Action
                        Text {
                            text: modelData.action
                            color: cText
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }
}
