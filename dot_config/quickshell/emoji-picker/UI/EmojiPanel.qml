import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../Services"

PanelWindow {
    id: root
    
    anchors.bottom: true
    anchors.top: true
    anchors.left: true
    anchors.right: true
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "emoji-picker"

    color: "transparent"

    readonly property color cBg: ThemeService.background
    readonly property color cSurface: ThemeService.surface
    readonly property color cAccent: ThemeService.accent
    readonly property color cText: ThemeService.text
    readonly property color cDim: ThemeService.text_dim

    property bool visible_state: false
    property string filterText: ""
    
    property var filteredEmojis: {
        var list = EmojiService.emojis
        if (filterText === "") return list
        var lower = filterText.toLowerCase()
        return list.filter(e => e.name.includes(lower))
    }

    Component.onCompleted: {
        console.log("EmojiPanel Component.onCompleted")
        EmojiService.scan()
        visible_state = true
        searchInput.forceActiveFocus()
        console.log("visible_state set to:", visible_state)
    }

    function close() {
        visible_state = false
        exitTimer.start()
    }

    Timer {
        id: exitTimer; interval: 250; onTriggered: Qt.quit()
    }

    // Background Close
    MouseArea {
        anchors.fill: parent
        onClicked: close()
        z: -1
    }

    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: 500
        height: 600
        color: Qt.rgba(cBg.r, cBg.g, cBg.b, 0.9)
        radius: 24
        border.color: Qt.rgba(1, 1, 1, 0.1)
        border.width: 1
        clip: true
        
        opacity: visible_state ? 1.0 : 0.0
        scale: visible_state ? 1.0 : 0.95
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

        MultiEffect {
            anchors.fill: parent; source: parent; blurEnabled: true; blur: 1.0; z: -1
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 25
            spacing: 12 // Reduced from 20

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 15
                Text { text: "󰞅"; color: cAccent; font.pixelSize: 22; font.family: "Symbols Nerd Font" }
                Text { text: "Emoji Picker"; color: cText; font.bold: true; font.pixelSize: 16; Layout.fillWidth: true }
                IconButton { icon: "󰅖"; onClicked: close() }
            }

            // Search
            Rectangle {
                Layout.fillWidth: true; height: 45; color: cSurface; radius: 12 // Reduced height
                border.color: searchInput.activeFocus ? cAccent : "transparent"; border.width: 2
                RowLayout {
                    anchors.fill: parent; anchors.margins: 10; spacing: 12
                    Text { text: "󰍉"; color: cAccent; font.pixelSize: 16; font.family: "Symbols Nerd Font" }
                    TextInput {
                        id: searchInput; Layout.fillWidth: true; verticalAlignment: TextInput.AlignVCenter
                        font.pixelSize: 14; color: cText; clip: true
                        onTextChanged: root.filterText = text
                        Keys.onEscapePressed: close()
                    }
                }
            }

            // Emoji Grid
            GridView {
                id: gridView
                Layout.fillWidth: true; Layout.fillHeight: true
                cellWidth: 50; cellHeight: 50 // Slightly more compact
                clip: true; focus: true
                model: root.filteredEmojis
                
                delegate: Rectangle {
                    width: 44; height: 44; radius: 10
                    color: mouseArea.containsMouse ? cSurface : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: modelData.char
                        font.pixelSize: 28
                    }
                    MouseArea {
                        id: mouseArea; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            EmojiService.copy(modelData.char)
                            close()
                        }
                    }
                    ToolTip {
                        visible: mouseArea.containsMouse
                        text: modelData.name.toUpperCase()
                        delay: 500
                    }
                }
            }
        }
    }

    component IconButton: Rectangle {
        property string icon: ""
        signal clicked()
        width: 32; height: 32; radius: 16; color: cSurface
        Text { anchors.centerIn: parent; text: icon; color: cText; font.pixelSize: 14; font.family: "Symbols Nerd Font" }
        MouseArea { anchors.fill: parent; hoverEnabled: true; onClicked: parent.clicked() }
    }
}
