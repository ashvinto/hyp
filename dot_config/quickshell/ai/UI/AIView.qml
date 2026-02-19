import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../../Common/Services" as Common

PanelWindow {
    id: root
    
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "ai-launcher"

    // --- Colors from Common ThemeService (Safe Access) ---
    readonly property color cBg: (typeof Common.ThemeService !== "undefined" && Common.ThemeService.backgroundDark) ? Common.ThemeService.backgroundDark : "#11111b"
    readonly property color cSurface: (typeof Common.ThemeService !== "undefined" && Common.ThemeService.surface) ? Common.ThemeService.surface : "#1e1e2e"
    readonly property color cAccent: (typeof Common.ThemeService !== "undefined" && Common.ThemeService.accent) ? Common.ThemeService.accent : "#cba6f7"
    readonly property color cText: (typeof Common.ThemeService !== "undefined" && Common.ThemeService.text) ? Common.ThemeService.text : "#cdd6f4"
    readonly property color cDim: (typeof Common.ThemeService !== "undefined" && Common.ThemeService.text_dim) ? Common.ThemeService.text_dim : "#6c7086"

    function close() { Qt.quit() }

    // Background Dim
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.4
        MouseArea { anchors.fill: parent; onClicked: root.close() }
    }

    Rectangle {
        id: container
        anchors.centerIn: parent
        width: 850
        height: 550
        radius: 24
        clip: true
        color: Qt.rgba(cBg.r, cBg.g, cBg.b, 0.95)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.1)

        focus: true
        Keys.onEscapePressed: root.close()

        layer.enabled: true
        layer.effect: MultiEffect { 
            shadowEnabled: true
            shadowBlur: 0.8
            shadowOpacity: 0.5
            shadowVerticalOffset: 8
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 40
            spacing: 30

            // Header
            RowLayout {
                spacing: 15
                Layout.alignment: Qt.AlignHCenter
                Text { text: "󰚩"; color: cAccent; font.pixelSize: 32; font.family: "Symbols Nerd Font" }
                Text { text: "AI HUB"; color: cText; font.bold: true; font.pixelSize: 24; font.letterSpacing: 2 }
            }

            // Grid of AI Tools
            GridLayout {
                columns: 2
                rowSpacing: 20
                columnSpacing: 20
                Layout.alignment: Qt.AlignHCenter
                Layout.fillHeight: true

                AICard { 
                    name: "ChatGPT"; desc: "OpenAI"; icon: "󰭹"; url: "https://chatgpt.com"; cardColor: "#74aa9c"
                }
                AICard { 
                    name: "Claude"; desc: "Anthropic"; icon: "󰚩"; url: "https://claude.ai"; cardColor: "#d97757"
                }
                AICard { 
                    name: "Gemini"; desc: "Google"; icon: "󰚩"; url: "https://gemini.google.com"; cardColor: "#4285f4"
                }
                AICard { 
                    name: "Perplexity"; desc: "Search AI"; icon: "󰍉"; url: "https://perplexity.ai"; cardColor: "#2d9cad"
                }
            }

            Text { 
                text: "Select a service to launch • Press ESC to close"
                color: cDim
                font.pixelSize: 11
                Layout.alignment: Qt.AlignHCenter 
            }
        }
    }

    component AICard: Rectangle {
        id: cardRoot
        property string name: ""
        property string desc: ""
        property string icon: ""
        property string url: ""
        property color cardColor: cAccent

        Layout.preferredWidth: 360
        Layout.preferredHeight: 110
        radius: 18
        color: hover.hovered ? Qt.rgba(cardColor.r, cardColor.g, cardColor.b, 0.12) : cSurface
        border.width: 1
        border.color: hover.hovered ? cardColor : "transparent"
        
        Behavior on color { ColorAnimation { duration: 200 } }
        Behavior on border.color { ColorAnimation { duration: 200 } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 25
            spacing: 20

            Rectangle {
                width: 54; height: 54; radius: 27
                color: Qt.rgba(cardColor.r, cardColor.g, cardColor.b, 0.2)
                Text { anchors.centerIn: parent; text: cardRoot.icon; color: cardRoot.cardColor; font.pixelSize: 26; font.family: "Symbols Nerd Font" }
            }

            ColumnLayout {
                spacing: 4; Layout.fillWidth: true
                Text { text: cardRoot.name; color: cText; font.bold: true; font.pixelSize: 18 }
                Text { text: cardRoot.desc; color: cDim; font.pixelSize: 12 }
            }

            Text { text: "󰁔"; color: hover.hovered ? cardColor : cDim; font.pixelSize: 20; font.family: "Symbols Nerd Font"; opacity: hover.hovered ? 1.0 : 0.3 }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                Quickshell.execDetached(["xdg-open", url])
                root.close()
            }
            HoverHandler { id: hover }
        }
    }
}