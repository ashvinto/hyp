import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "../Services"

PanelWindow {
    id: root
    
    required property var notification
    property int yOffset: 0
    
    anchors.top: true
    anchors.right: true
    
    margins {
        top: 15 + root.yOffset
        right: 15
    }
    
    Behavior on margins.top { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
    
    implicitWidth: 360
    implicitHeight: 100
    
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "notification"
    visible: true
    
    property bool active: false
    
    // --- Theme Access ---
    readonly property color cBg: ThemeService.background
    readonly property color cSurface: ThemeService.surface
    readonly property color cAccent: ThemeService.accent
    readonly property color cText: ThemeService.text
    readonly property color cDim: ThemeService.text_dim
    readonly property color cRed: ThemeService.error

    Timer {
        id: autoClose
        interval: 6000
        running: true
        onTriggered: root.destroy()
    }

    Rectangle {
        id: panel
        anchors.fill: parent
        color: Qt.rgba(cBg.r, cBg.g, cBg.b, 0.95)
        radius: 20
        border.color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.2)
        border.width: 1
        clip: true
        
        x: active ? 0 : 400
        Behavior on x { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.3)
            shadowBlur: 0.6
            shadowVerticalOffset: 4
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16

            // App Icon with Glow
            Rectangle {
                width: 56; height: 56; radius: 16
                color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.1)
                border.color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.1)
                
                Image {
                    anchors.fill: parent
                    anchors.margins: 10
                    source: root.notification.icon || "image://icon/dialog-information"
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }
            }

            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                
                Text {
                    text: root.notification.summary || "Notification"
                    color: cText
                    font.bold: true
                    font.pixelSize: 14
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                
                Text {
                    text: root.notification.body || ""
                    color: cDim
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    opacity: 0.9
                }
            }

            // Close Button
            Rectangle {
                width: 32; height: 32; radius: 16
                color: closeHover.hovered ? Qt.rgba(cRed.r, cRed.g, cRed.b, 0.15) : "transparent"
                
                Text { 
                    anchors.centerIn: parent
                    text: "󰅖"
                    color: closeHover.hovered ? cRed : cDim
                    font.pixelSize: 16; font.family: "Symbols Nerd Font"
                }
                
                MouseArea { 
                    id: closeArea; anchors.fill: parent
                    onClicked: root.destroy() 
                }
                HoverHandler { id: closeHover }
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }
        
        // Progress bar for auto-close
        Rectangle {
            anchors.bottom: parent.bottom
            height: 3
            color: cAccent
            opacity: 0.4
            width: parent.width * (1 - (progressTimer.count / 60))
            
            Timer {
                id: progressTimer
                property int count: 0
                interval: 100; running: true; repeat: true
                onTriggered: count++
            }
        }
    }
}
