import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

PanelWindow {
    id: root
    
    required property var notification
    property int yOffset: 0
    
    anchors.bottom: true
    anchors.horizontalCenter: true
    
    margins {
        bottom: 15 + root.yOffset
    }
    
    Behavior on margins.bottom { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    
    implicitWidth: 350
    implicitHeight: 85
    
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "notification"
    visible: true
    
    property bool active: false
    
    Timer {
        id: autoClose
        interval: 5000
        running: true
        onTriggered: root.destroy()
    }

    Rectangle {
        id: panel
        anchors.fill: parent
        color: Qt.rgba(0.07, 0.07, 0.11, 0.85) // Dark Translucent
        radius: 16
        border.color: Qt.rgba(1, 1, 1, 0.1)
        border.width: 1
        clip: true
        
        y: active ? 0 : 150
        Behavior on y { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 15

            // App Icon
            Rectangle {
                width: 45; height: 45; radius: 12
                color: Qt.rgba(1, 1, 1, 0.05)
                Image {
                    anchors.fill: parent
                    anchors.margins: 5
                    source: root.notification.icon || "image://icon/dialog-information"
                    fillMode: Image.PreserveAspectFit
                }
            }

            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                
                Text {
                    text: root.notification.summary
                    color: "#cdd6f4"
                    font.bold: true
                    font.pixelSize: 13
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                
                Text {
                    text: root.notification.body
                    color: "#a6adc8"
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // Close Button
            IconButton {
                icon: "󰅖"
                onClicked: root.destroy()
            }
        }
    }

    component IconButton: Rectangle {
        property string icon: ""
        signal clicked()
        width: 24; height: 24; radius: 12; color: "transparent"
        Text { anchors.centerIn: parent; text: icon; color: "#6c7086"; font.pixelSize: 14; font.family: "Symbols Nerd Font" }
        MouseArea { 
            anchors.fill: parent; hoverEnabled: true
            onEntered: parent.children[0].color = "#f38ba8"
            onExited: parent.children[0].color = "#6c7086"
            onClicked: parent.clicked() 
        }
    }
}
