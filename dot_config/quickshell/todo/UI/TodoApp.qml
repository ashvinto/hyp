import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../Services"

PanelWindow {
    id: root

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "todo"

    // Property to track visibility state
    property bool visible_state: false
    Component.onCompleted: visible_state = true

    function close() {
        visible_state = false
        exitTimer.start()
    }

    Timer {
        id: exitTimer
        interval: 300
        onTriggered: Qt.quit()
    }

    // Colors
    readonly property color cCard: "#1e1e2e"
    readonly property color cText: "#cdd6f4"
    readonly property color cDim: "#a6adc8"
    readonly property color cAccent: "#cba6f7"
    readonly property color cSurface: "#313244"
    readonly property color cBorder: Qt.rgba(1, 1, 1, 0.08)
    readonly property color cRed: "#f38ba8"
    readonly property color cGreen: "#a6e3a1"

    // Main UI Container
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        opacity: visible_state ? 1 : 0
        Behavior on opacity { 
            NumberAnimation { 
                duration: 300; 
                easing.type: Easing.OutCubic 
            } 
        }

        MouseArea { 
            anchors.fill: parent; 
            onClicked: root.close() 
        }
        
        focus: true; 
        Keys.onEscapePressed: root.close()

        // Background blur effect
        MultiEffect {
            anchors.fill: parent; 
            source: bgRect; 
            blurEnabled: true; 
            blur: 0.8; 
            brightness: 0.4
        }
        
        Rectangle { 
            id: bgRect; 
            anchors.fill: parent; 
            color: Qt.rgba(0,0,0,0.5); 
            visible: false 
        }

        // Main Todo Container
        Rectangle {
            id: todoContainer
            anchors.centerIn: parent
            width: 350
            height: 500
            color: cCard
            radius: 16
            border.width: 1
            border.color: cBorder
            clip: true

            layer.enabled: true
            layer.effect: MultiEffect { 
                shadowEnabled: true; 
                shadowOpacity: 0.2; 
                shadowBlur: 0.6; 
                shadowVerticalOffset: 5 
            }

            // Transform animation
            transform: Scale {
                origin.x: todoContainer.width/2; 
                origin.y: todoContainer.height/2
                xScale: visible_state ? 1 : 0.95; 
                yScale: visible_state ? 1 : 0.95
                Behavior on xScale { 
                    NumberAnimation { 
                        duration: 400; 
                        easing.type: Easing.OutBack 
                    } 
                }
                Behavior on yScale { 
                    NumberAnimation { 
                        duration: 400; 
                        easing.type: Easing.OutBack 
                    } 
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    Text {
                        text: "📝 Todo List"
                        color: cText
                        font.pixelSize: 20
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    
                    // Close button
                    Rectangle {
                        width: 32; height: 32; radius: 16
                        color: cSurface
                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: cText
                            font.pixelSize: 16
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.close()
                        }
                    }
                }

                // Input area for new todos
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    TextField {
                        id: todoInput
                        placeholderText: "Add a new task..."
                        color: cText
                        background: Rectangle {
                            color: cSurface
                            radius: 8
                            border.color: cBorder
                            border.width: 1
                        }
                        Layout.fillWidth: true
                        Keys.onReturnPressed: addTodo()
                        Keys.onEnterPressed: addTodo()
                    }
                    
                    Button {
                        text: "Add"
                        onClicked: addTodo()
                        background: Rectangle {
                            color: cAccent
                            radius: 6
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "#1e1e2e"
                            font.bold: true
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                // Todo list
                ListView {
                    id: todoList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: TodoService.todos
                    clip: true

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 40
                        color: index % 2 === 0 ? Qt.rgba(cSurface.r, cSurface.g, cSurface.b, 0.5) : Qt.rgba(cCard.r, cCard.g, cCard.b, 0.5)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            // Checkbox
                            Rectangle {
                                width: 20; height: 20; radius: 10
                                color: modelData.completed ? cGreen : cSurface
                                border.color: modelData.completed ? cGreen : cDim
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.completed ? "✓" : ""
                                    color: cCard
                                    font.pixelSize: 10
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: TodoService.toggleTodo(index)
                                }
                            }

                            // Task text
                            Text {
                                text: modelData.task
                                color: modelData.completed ? cDim : cText
                                font.pixelSize: 12
                                font.strikeout: modelData.completed
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                verticalAlignment: Text.AlignVCenter
                            }

                            // Delete button
                            Rectangle {
                                width: 20; height: 20; radius: 10
                                color: cRed

                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    color: cCard
                                    font.pixelSize: 10
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: TodoService.removeTodo(index)
                                }
                            }
                        }
                    }

                    // Empty state
                    Text {
                        anchors.centerIn: parent
                        text: "No tasks yet. Add one above!"
                        color: cDim
                        font.pixelSize: 14
                        visible: TodoService.todos.length === 0
                    }
                }

                // Stats
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    Text {
                        text: `${TodoService.completedCount} completed`
                        color: cGreen
                        font.pixelSize: 12
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    // Clear Completed Button
                    Button {
                        text: "Clear Done"
                        visible: TodoService.completedCount > 0
                        onClicked: TodoService.clearCompleted()
                        background: Rectangle {
                            color: "transparent"
                            border.color: cRed
                            border.width: 1
                            radius: 4
                        }
                        contentItem: Text {
                            text: parent.text
                            color: cRed
                            font.pixelSize: 10
                            font.bold: true
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                    
                    Text {
                        text: `${TodoService.pendingCount} pending`
                        color: cAccent
                        font.pixelSize: 12
                        font.bold: true
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }

    // Function to add a new todo
    function addTodo() {
        if (todoInput.text.trim() !== "") {
            TodoService.addTodo(todoInput.text.trim())
            todoInput.text = ""
        }
    }
}