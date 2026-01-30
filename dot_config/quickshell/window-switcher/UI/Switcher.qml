import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../Services" as Services

PanelWindow {
    id: root

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "window-switcher"

    // Use the Services prefix to ensure singletons are resolved
    readonly property color cBg: Services.ThemeService.background
    readonly property color cSurface: Services.ThemeService.surface
    readonly property color cAccent: Services.ThemeService.accent
    readonly property color cText: Services.ThemeService.text
    readonly property color cDim: Services.ThemeService.text_dim

    property int currentIndex: 0
    property var windows: Hyprland.toplevels.values

    function next() {
        if (windows.length === 0) return
        currentIndex = (currentIndex + 1) % windows.length
    }

    function select() {
        if (windows.length > 0) {
            var win = windows[root.currentIndex]
            Quickshell.execDetached(["sh", "-c", "hyprctl dispatch workspace " + win.workspace.id + " && hyprctl dispatch focuswindow address:" + win.address])
        }
        Qt.quit()
    }

    // Main Container to hold focus and keys (Item derived)
    Item {
        anchors.fill: parent
        focus: true
        
        Keys.onTabPressed: root.next()
        Keys.onSpacePressed: root.select()
        Keys.onReturnPressed: root.select()
        Keys.onEscapePressed: Qt.quit()

        Rectangle {
            anchors.fill: parent
            color: "#88000000"
            MouseArea { anchors.fill: parent; onClicked: Qt.quit() }
        }

        Rectangle {
            id: panel
            anchors.centerIn: parent
            width: Math.min(listView.contentWidth + 100, 1200)
            height: 220
            color: Qt.rgba(cBg.r, cBg.g, cBg.b, 0.85)
            radius: 32
            border.color: Qt.rgba(1, 1, 1, 0.1)
            border.width: 1
            clip: true

            MultiEffect {
                anchors.fill: parent; source: parent; blurEnabled: true; blur: 1.0; z: -1
            }

            ListView {
                id: listView
                anchors.fill: parent
                anchors.margins: 30
                orientation: ListView.Horizontal
                model: root.windows
                spacing: 25
                currentIndex: root.currentIndex
                
                preferredHighlightBegin: parent.width / 2 - 75
                preferredHighlightEnd: parent.width / 2 + 75
                highlightRangeMode: ListView.ApplyRange

                delegate: Item {
                    width: 150; height: 160
                    
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 12
                        
                        Rectangle {
                            id: card
                            Layout.alignment: Qt.AlignHCenter
                            width: 120; height: 120; radius: 24
                            color: root.currentIndex === index ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.15) : Qt.rgba(1, 1, 1, 0.05)
                            
                            border.color: root.currentIndex === index ? cAccent : Qt.rgba(1, 1, 1, 0.1)
                            border.width: root.currentIndex === index ? 2 : 1
                            
                            Image {
                                anchors.fill: parent
                                anchors.margins: 25
                                sourceSize: Qt.size(128, 128)
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true

                                source: {
                                    if (!modelData) return "image://icon/system-run"
                                    var cls = (modelData.class || "").toLowerCase()

                                    // Explicit Overrides
                                    if (cls.includes("vivaldi")) return "image://icon/vivaldi-stable"
                                    if (cls.includes("foot")) return "image://icon/foot"
                                    if (cls.includes("kitty")) return "image://icon/kitty"
                                    if (cls.includes("code")) return "image://icon/com.visualstudio.code"
                                    if (cls.includes("discord")) return "image://icon/discord"

                                    if (cls !== "") return "image://icon/" + cls
                                    return "image://icon/system-run"
                                }

                                onStatusChanged: if (status === Image.Error) source = "image://icon/system-run"
                            }

                            Rectangle {
                                anchors.top: parent.top; anchors.right: parent.right
                                anchors.margins: 8
                                width: 24; height: 24; radius: 12
                                color: root.currentIndex === index ? cAccent : cSurface
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.workspace ? modelData.workspace.id : "?"
                                    color: root.currentIndex === index ? cBg : cText
                                    font.bold: true; font.pixelSize: 10
                                }
                            }
                            
                            Behavior on color { ColorAnimation { duration: 200 } }
                            Behavior on border.color { ColorAnimation { duration: 200 } }
                        }

                        ColumnLayout {
                            spacing: 2
                            Layout.alignment: Qt.AlignHCenter
                            Text {
                                text: {
                                    if (!modelData) return "App"
                                    var name = modelData.class || ""
                                    if (name === "" && modelData.title) name = modelData.title.split(" ")[0]
                                    return name.toUpperCase()
                                }
                                color: root.currentIndex === index ? cAccent : cText
                                font.pixelSize: 11; font.bold: true; font.letterSpacing: 1
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: modelData ? modelData.title : ""
                                color: cDim
                                font.pixelSize: 10
                                Layout.maximumWidth: 140
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                                visible: text !== ""
                            }
                        }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: root.currentIndex = index
                        onClicked: root.select()
                    }
                }
            }
        }
    }
}
