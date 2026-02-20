import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import "../Services"

ColumnLayout {
    id: root
    property bool readOnly: false
    spacing: 14 // Increased breathing space

    // Colors
    readonly property color cBg: ThemeService.background
    readonly property color cSurface: ThemeService.surface
    readonly property color cAccent: ThemeService.accent
    readonly property color cText: ThemeService.text
    readonly property color cDim: ThemeService.text_dim
    readonly property color cRed: ThemeService.error
    readonly property color cGreen: ThemeService.success

    // Input area
    RowLayout {
        visible: !root.readOnly
        Layout.fillWidth: true
        spacing: 12
        
        TextField {
            id: todoInput
            placeholderText: "Add a task..."
            color: cText
            font.pixelSize: 13
            Layout.fillWidth: true
            padding: 12
            background: Rectangle {
                color: Qt.rgba(1, 1, 1, 0.03); radius: 14
                border.color: parent.activeFocus ? cAccent : Qt.rgba(1, 1, 1, 0.05)
                border.width: 1
            }
            onAccepted: addTodo()
        }
        
        Rectangle {
            width: 40; height: 40; radius: 14; color: cAccent
            Text { anchors.centerIn: parent; text: "󰐕"; color: "black"; font.pixelSize: 18; font.family: "Symbols Nerd Font" }
            MouseArea { anchors.fill: parent; onClicked: addTodo() }
        }
    }

    function addTodo() {
        if (todoInput.text.trim() !== "") {
            TodoService.addTodo(todoInput.text.trim())
            todoInput.text = ""
        }
    }

    // Task List
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        ListView {
            id: listView
            anchors.fill: parent
            model: TodoService.todos
            spacing: 4 // Tighter task spacing
            interactive: true
            boundsBehavior: Flickable.StopAtBounds

            delegate: Item {
                id: delegateRoot
                width: listView.width
                height: 44 // Reduced height
                
                Rectangle {
                    id: itemRect
                    anchors.fill: parent
                    radius: 12
                    color: "transparent"
                    border.width: 1
                    border.color: mouseArea.containsMouse ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.1) : "transparent"
                    
                    // Subtle background
                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        color: Qt.rgba(1, 1, 1, 0.02)
                        opacity: mouseArea.containsMouse ? 1.5 : 1.0
                    }

                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 12

                        // Checkbox - Visually lighter
                        Rectangle {
                            width: 16; height: 18; radius: 5
                            color: modelData.completed ? cGreen : "transparent"
                            border.color: modelData.completed ? cGreen : Qt.rgba(cText.r, cText.g, cText.b, 0.15)
                            border.width: 1.2

                            Text {
                                anchors.centerIn: parent; text: "󰄬"
                                color: "black"; font.pixelSize: 9; font.family: "Symbols Nerd Font"
                                visible: modelData.completed
                            }

                            MouseArea { anchors.fill: parent; onClicked: TodoService.toggleTodo(index) }
                        }

                        ColumnLayout {
                            spacing: -2; Layout.fillWidth: true
                            Text {
                                text: modelData.task
                                color: modelData.completed ? cDim : cText
                                font.pixelSize: 12; font.bold: !modelData.completed
                                font.strikeout: modelData.completed
                                elide: Text.ElideRight; Layout.fillWidth: true
                                opacity: modelData.completed ? 0.5 : 0.9
                            }
                            Text {
                                text: modelData.timestamp ? Qt.formatDateTime(new Date(modelData.timestamp), "hh:mm A") : ""
                                color: cDim; font.pixelSize: 8; opacity: 0.4; visible: text !== ""
                            }
                        }

                        // Delete
                        Text {
                            text: "󰅖"; color: cRed; font.pixelSize: 14; font.family: "Symbols Nerd Font"
                            opacity: mouseArea.containsMouse ? 0.6 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                            MouseArea { anchors.fill: parent; onClicked: TodoService.removeTodo(index) }
                        }
                    }
                }
                MouseArea { id: mouseArea; anchors.fill: parent; hoverEnabled: true; propagateComposedEvents: true }
            }
        }

        // Soft Fade Mask
        Rectangle {
            anchors.bottom: parent.bottom; width: parent.width; height: 30
            visible: listView.contentHeight > listView.height
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: Qt.rgba(0,0,0,0.15) }
            }
        }
    }

    // Footer
    RowLayout {
        Layout.fillWidth: true; visible: TodoService.todos.length > 0
        opacity: 0.6
        Text { 
            text: TodoService.pendingCount + " tasks remaining"; 
            color: cAccent; font.pixelSize: 9; font.bold: true
        }
        Item { Layout.fillWidth: true }
        Text { 
            text: "Clear Completed"; color: cRed; font.pixelSize: 9; font.bold: true; visible: TodoService.completedCount > 0
            MouseArea { anchors.fill: parent; onClicked: TodoService.clearCompleted() }
        }
    }
}
