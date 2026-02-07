import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../Services"

PanelWindow {
    id: root
    
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: "transparent"
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "clipboard"

    // Background Dim
    Rectangle {
        anchors.fill: parent
        color: "#66000000"
        opacity: visible_state ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 300 } }
        MouseArea { anchors.fill: parent; onClicked: close() }
    }

    readonly property color cBg: ThemeService.background
    readonly property color cSurface: ThemeService.surface
    readonly property color cAccent: ThemeService.accent
    readonly property color cText: ThemeService.text
    readonly property color cDim: ThemeService.text_dim

    property bool visible_state: false
    
    Component.onCompleted: {
        ClipboardService.refresh()
        visible_state = true
        searchInput.forceActiveFocus()
    }

    function close() {
        visible_state = false
        exitTimer.start()
    }

    Timer {
        id: exitTimer
        interval: 300
        onTriggered: Qt.quit()
    }

    property string filterText: ""
    property var filteredHistory: {
        var hist = ClipboardService.history
        if (filterText === "") return hist
        var lower = filterText.toLowerCase()
        return hist.filter(item => item.preview.toLowerCase().includes(lower))
    }

    // Sidebar Container
    Item {
        id: sidebar
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 450
        
        x: visible_state ? 0 : -width
        Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

        // Glass Effect
        MultiEffect {
            anchors.fill: panel
            source: panel
            blurEnabled: true
            blur: 1.0
            brightness: -0.1
            saturation: 0.2
            z: -1
        }

        Rectangle {
            id: panel
            anchors.fill: parent
            color: Qt.rgba(cBg.r, cBg.g, cBg.b, 0.85)
            border.color: Qt.rgba(1, 1, 1, 0.1)
            border.width: 1
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 30
                spacing: 25

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 15
                    Text { 
                        text: "󰅍" 
                        color: cAccent
                        font.pixelSize: 24
                        font.family: "Symbols Nerd Font"
                    }
                    Text { 
                        text: "Clipboard History"
                        color: cText
                        font.bold: true
                        font.pixelSize: 18
                        Layout.fillWidth: true
                    }
                    IconButton { 
                        icon: "󰅖" 
                        onClicked: close()
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
                        anchors.margins: 12; spacing: 12
                        Text { text: "󰍉"; color: cAccent; font.pixelSize: 18; font.family: "Symbols Nerd Font" }
                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            verticalAlignment: TextInput.AlignVCenter
                            font.pixelSize: 14; color: cText; clip: true
                            onTextChanged: { root.filterText = text; listView.currentIndex = 0 }
                            Keys.onDownPressed: listView.forceActiveFocus()
                            Keys.onEscapePressed: close()
                        }
                    }
                }

                // List
                ListView {
                    id: listView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: root.filteredHistory
                    spacing: 8
                    
                    highlight: Rectangle {
                        color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.15)
                        radius: 12
                        border.color: cAccent
                        border.width: 1 
                    }
                    highlightFollowsCurrentItem: true
                    highlightMoveDuration: 200

                    delegate: Item {
                        width: listView.width
                        height: 60
                        
                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            radius: 12
                            
                            HoverHandler { id: hoverHandler }

                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: listView.currentIndex = index
                                onClicked: {
                                    ClipboardService.select(modelData.full)
                                    close()
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 15; spacing: 15
                                
                                Text {
                                    text: (index + 1)
                                    color: cDim
                                    font.pixelSize: 10
                                    font.bold: true
                                    Layout.preferredWidth: 20
                                }

                                Text {
                                    text: modelData.preview.replace(/\n/g, " ")
                                    color: cText
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                
                                IconButton {
                                    icon: "󰆴" // Trash icon
                                    visible: hoverHandler.hovered
                                    onClicked: {
                                        console.log("UI: Deleting index", index)
                                        ClipboardService.deleteItem(modelData.full, index)
                                        // No close() call here
                                    }
                                }
                            }
                        }
                    }

                    // Empty State
                    Text {
                        anchors.centerIn: parent
                        text: "No history found"
                        color: cDim
                        visible: listView.count === 0
                        font.pixelSize: 14
                    }

                    Keys.onReturnPressed: {
                        if (currentIndex >= 0 && currentIndex < root.filteredHistory.length) {
                            ClipboardService.select(root.filteredHistory[currentIndex].full)
                            close()
                        }
                    }
                    Keys.onUpPressed: {
                        if (currentIndex <= 0) { searchInput.forceActiveFocus(); currentIndex = -1 }
                        else decrementCurrentIndex()
                    }
                    Keys.onEscapePressed: close()
                }

                // Footer
                Button {
                    Layout.fillWidth: true
                    height: 45
                    text: "Clear History"
                    onClicked: ClipboardService.clear()
                    background: Rectangle {
                        color: parent.hovered ? "#f38ba8" : cSurface
                        radius: 12
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                    contentItem: Text {
                        text: parent.text
                        color: parent.hovered ? cBg : cText
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter 
                    }
                }
            }
        }
    }

    component IconButton: Rectangle {
        property string icon: ""
        signal clicked(var mouse)
        width: 32; height: 32; radius: 16; color: mouseArea.containsMouse ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.2) : cSurface
        Text { anchors.centerIn: parent; text: icon; color: cText; font.pixelSize: 14; font.family: "Symbols Nerd Font" }
        MouseArea { 
            id: mouseArea
            anchors.fill: parent; 
            hoverEnabled: true; 
            onClicked: (mouse) => {
                parent.clicked(mouse)
                mouse.accepted = true
            }
        }
    }
}
