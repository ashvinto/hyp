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
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "keybind-manager"

    readonly property color cBg: Services.ThemeService.background
    readonly property color cSurface: Services.ThemeService.surface
    readonly property color cAccent: Services.ThemeService.accent
    readonly property color cText: Services.ThemeService.text
    readonly property color cDim: Services.ThemeService.text_dim
    readonly property color cError: Services.ThemeService.error || "#ff0000"

    Component.onCompleted: Services.KeybindService.load()

    property string filterText: ""
    property var visibleBinds: {
        var list = Services.KeybindService.binds
        if (filterText === "") return list
        var lower = filterText.toLowerCase()
        return list.filter(b => 
            (b.mods && b.mods.toLowerCase().includes(lower)) || 
            (b.key && b.key.toLowerCase().includes(lower)) || 
            (b.dispatcher && b.dispatcher.toLowerCase().includes(lower)) ||
            (b.args && b.args.toLowerCase().includes(lower))
        )
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
        height: 700
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
                Text { text: ""; color: cAccent; font.pixelSize: 24; font.family: "Symbols Nerd Font" }
                Text { text: "Keybinding Manager"; color: cText; font.bold: true; font.pixelSize: 20; Layout.fillWidth: true }
                
                TextField {
                    placeholderText: "Search..."
                    font.pixelSize: 14
                    color: cText
                    background: Rectangle { color: cSurface; radius: 8 }
                    Layout.preferredWidth: 200
                    onTextChanged: root.filterText = text
                }
                
                Button {
                    text: "+ Add New"
                    onClicked: addPopup.open()
                    background: Rectangle { color: cSurface; radius: 8; border.color: cAccent; border.width: 1 }
                    contentItem: Text { text: parent.text; color: cAccent; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }

                Button {
                    text: " Restore"
                    font.family: "Symbols Nerd Font"
                    onClicked: {
                        Services.KeybindService.restore()
                    }
                    background: Rectangle { color: cSurface; radius: 8; border.color: cDim; border.width: 1 }
                    contentItem: Text { text: parent.text; color: cDim; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }

                Button {
                    text: "Save & Reload"
                    onClicked: {
                        Services.KeybindService.save(Services.KeybindService.binds)
                        Qt.quit()
                    }
                    background: Rectangle { color: parent.down ? Qt.darker(cAccent) : cAccent; radius: 8 }
                    contentItem: Text { text: parent.text; color: cBg; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
            }

            // Header Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Text { text: "MODS"; color: cDim; font.bold: true; font.pixelSize: 12; Layout.preferredWidth: 100 }
                Text { text: "KEY"; color: cDim; font.bold: true; font.pixelSize: 12; Layout.preferredWidth: 80 }
                Text { text: "ACTION"; color: cDim; font.bold: true; font.pixelSize: 12; Layout.preferredWidth: 150 }
                Text { text: "COMMAND"; color: cDim; font.bold: true; font.pixelSize: 12; Layout.fillWidth: true }
                Item { width: 40; height: 1 } // Spacer for delete button
            }

            // List
            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: root.visibleBinds
                spacing: 8

                ScrollBar.vertical: ScrollBar {
                    id: vbar
                    active: true
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: 6
                        implicitHeight: 100
                        radius: 3
                        color: vbar.pressed ? cAccent : (vbar.hovered ? Qt.lighter(cDim, 1.2) : cDim)
                        opacity: 0.5
                    }
                }

                delegate: Rectangle {
                    id: delegateRoot
                    width: list.width - (vbar.visible ? 10 : 0)
                    height: 50
                    color: modelData.deleted ? Qt.rgba(cError.r, cError.g, cError.b, 0.1) : (modelData.isNew ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.1) : (itemMouseArea.containsMouse ? Qt.lighter(cSurface, 1.1) : cSurface))
                    radius: 12
                    border.color: modelData.deleted ? cError : (modelData.isNew ? cAccent : "transparent")
                    border.width: (modelData.deleted || modelData.isNew) ? 1 : 0
                    
                    Behavior on color { ColorAnimation { duration: 150 } }

                    MouseArea {
                        id: itemMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: forceActiveFocus()
                    }
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 15
                        opacity: modelData.deleted ? 0.4 : 1.0
                        
                        TextField {
                            text: modelData.mods
                            color: cAccent
                            font.bold: true
                            font.pixelSize: 13
                            background: null
                            Layout.preferredWidth: 120
                            enabled: !modelData.deleted
                            onTextEdited: Services.KeybindService.updateBinding(modelData.id, "mods", text)
                            placeholderText: "Mods..."
                            placeholderTextColor: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.4)
                        }
                        
                        TextField {
                            text: modelData.key
                            color: cText
                            font.bold: true
                            font.pixelSize: 13
                            background: null
                            Layout.preferredWidth: 80
                            enabled: !modelData.deleted
                            onTextEdited: Services.KeybindService.updateBinding(modelData.id, "key", text)
                            placeholderText: "Key..."
                            placeholderTextColor: Qt.rgba(cText.r, cText.g, cText.b, 0.4)
                        }
                        
                        TextField {
                            text: modelData.dispatcher
                            color: cDim
                            font.pixelSize: 13
                            background: null
                            Layout.preferredWidth: 150
                            enabled: !modelData.deleted
                            onTextEdited: Services.KeybindService.updateBinding(modelData.id, "dispatcher", text)
                            placeholderText: "Action..."
                            placeholderTextColor: Qt.rgba(cDim.r, cDim.g, cDim.b, 0.4)
                        }
                        
                        TextField {
                            text: modelData.args
                            color: cText
                            font.pixelSize: 13
                            background: null
                            Layout.fillWidth: true
                            enabled: !modelData.deleted
                            onTextEdited: Services.KeybindService.updateBinding(modelData.id, "args", text)
                            placeholderText: "Arguments..."
                            placeholderTextColor: Qt.rgba(cText.r, cText.g, cText.b, 0.4)
                        }

                        Button {
                            id: deleteBtn
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            hoverEnabled: true
                            background: Rectangle { 
                                color: deleteBtn.hovered ? Qt.rgba(cError.r, cError.g, cError.b, 0.15) : "transparent"
                                radius: 8
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            contentItem: Text { 
                                text: modelData.deleted ? "" : ""
                                color: modelData.deleted ? cAccent : (deleteBtn.hovered ? cError : cDim)
                                font.family: "Symbols Nerd Font"
                                font.pixelSize: 16
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter 
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            onClicked: {
                                if (modelData.deleted) {
                                    Services.KeybindService.restoreBinding(modelData.id)
                                } else {
                                    Services.KeybindService.removeBinding(modelData.id)
                                }
                            }
                        }
                    }
                }
            }
        }

        // Add Binding Popup
        Popup {
            id: addPopup
            anchors.centerIn: parent
            width: 500
            height: 400
            modal: true
            focus: true
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
            
            background: Rectangle {
                color: cBg
                radius: 16
                border.color: cAccent
                border.width: 1
            }

            // Conflict Detection Logic
            property bool hasConflict: {
                var newModsLower = newMods.text.toLowerCase().trim()
                var newKeyLower = newKey.text.toLowerCase().trim()
                
                // Don't flag empty inputs
                if (newKeyLower === "") return false

                return Services.KeybindService.binds.some(b => 
                    !b.deleted && 
                    b.mods.toLowerCase().trim() === newModsLower && 
                    b.key.toLowerCase().trim() === newKeyLower
                )
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 15

                Text { 
                    text: "Add New Keybinding"
                    color: cText
                    font.bold: true
                    font.pixelSize: 18
                    Layout.alignment: Qt.AlignHCenter
                }

                GridLayout {
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 10
                    Layout.fillWidth: true

                    Text { text: "Mods:"; color: cDim; font.bold: true }
                    TextField { 
                        id: newMods
                        placeholderText: "SUPER, CTRL, SHIFT..."
                        Layout.fillWidth: true 
                        color: cText
                        background: Rectangle { color: cSurface; radius: 6 }
                    }

                    Text { text: "Key:"; color: cDim; font.bold: true }
                    TextField { 
                        id: newKey
                        placeholderText: "Q, Return, 1..."
                        Layout.fillWidth: true 
                        color: cText
                        background: Rectangle { 
                            color: cSurface
                            radius: 6 
                            border.color: addPopup.hasConflict ? cError : "transparent"
                            border.width: addPopup.hasConflict ? 1 : 0
                        }
                    }

                    Text { text: "Dispatcher:"; color: cDim; font.bold: true }
                    TextField { 
                        id: newDispatcher
                        placeholderText: "exec, killactive, workspace..."
                        Layout.fillWidth: true 
                        color: cText
                        background: Rectangle { color: cSurface; radius: 6 }
                    }

                    Text { text: "Args:"; color: cDim; font.bold: true }
                    TextField { 
                        id: newArgs
                        placeholderText: "command or arguments"
                        Layout.fillWidth: true 
                        color: cText
                        background: Rectangle { color: cSurface; radius: 6 }
                    }
                }

                // Status / Warning Message
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20
                    Text {
                        anchors.centerIn: parent
                        text: addPopup.hasConflict ? "⚠️ Warning: This keybind already exists!" : ""
                        color: cError
                        font.bold: true
                        visible: addPopup.hasConflict
                    }
                }

                Item { Layout.fillHeight: true } // Spacer

                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: 10

                    Button {
                        text: "Cancel"
                        onClicked: addPopup.close()
                        background: Rectangle { color: "transparent"; radius: 6; border.color: cDim; border.width: 1 }
                        contentItem: Text { text: parent.text; color: cDim; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    }

                    Button {
                        text: "Add"
                        // Disable if key or dispatcher is empty
                        enabled: newKey.text.length > 0 && newDispatcher.text.length > 0
                        opacity: enabled ? 1.0 : 0.5
                        
                        onClicked: {
                            Services.KeybindService.addBinding(newMods.text, newKey.text, newDispatcher.text, newArgs.text)
                            newMods.text = ""
                            newKey.text = ""
                            newDispatcher.text = ""
                            newArgs.text = ""
                            addPopup.close()
                        }
                        background: Rectangle { color: cAccent; radius: 6 }
                        contentItem: Text { text: parent.text; color: cBg; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    }
                }
            }
        }
    }
}
