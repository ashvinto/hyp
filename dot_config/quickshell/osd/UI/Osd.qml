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
    anchors.left: true
    anchors.right: true
    
    implicitHeight: 150
    
    // Crucial: exclusiveZone 0 ensures it doesn't move other windows
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "osd"

    color: "transparent"
    
    property bool visible_state: false
    property string currentIcon: "󰕾"
    property real currentValue: 0
    property string label: "Volume"

    Timer {
        id: hideTimer
        interval: 2000
        onTriggered: {
            visible_state = false
            // Wait for fade animation then kill process to save memory
            exitTimer.start()
        }
    }

    Timer {
        id: exitTimer
        interval: 300
        onTriggered: Qt.quit()
    }

    function show(icon, val, txt) {
        currentIcon = icon
        currentValue = val
        label = txt
        visible_state = true
        hideTimer.restart()
    }

    Connections {
        target: VolumeService
        function onChanged() {
            show(VolumeService.muted ? "󰝟" : "󰕾", VolumeService.volume / 100, "Volume")
        }
    }

    Connections {
        target: BrightnessService
        function onChanged() {
            show("󰃠", BrightnessService.brightness / 100, "Brightness")
        }
    }
    
    Component.onCompleted: {
        // Initial show to ensure it pops up immediately when process starts
        show(VolumeService.muted ? "󰝟" : "󰕾", VolumeService.volume / 100, "Volume")
    }

    Rectangle {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 80
        
        width: 240
        height: 54
        
        color: Qt.rgba(0.1, 0.1, 0.15, 0.7) // Glass Tint
        radius: 27
        border.color: Qt.rgba(1, 1, 1, 0.15)
        border.width: 1
        opacity: visible_state ? 1.0 : 0.0
        scale: visible_state ? 1.0 : 0.9
        clip: true

        Behavior on opacity { NumberAnimation { duration: 250 } }
        Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }

        MultiEffect {
            anchors.fill: parent
            source: parent
            blurEnabled: true
            blur: 1.0
            z: -1
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 15; spacing: 15

            Text {
                text: root.currentIcon
                color: "#cba6f7"
                font.pixelSize: 20
                font.family: "Symbols Nerd Font"
            }

            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 6; radius: 3; color: Qt.rgba(1, 1, 1, 0.1)
                    Rectangle {
                        width: parent.width * root.currentValue
                        height: parent.height; radius: 3; color: "#cba6f7"
                        Behavior on width { NumberAnimation { duration: 150 } }
                    }
                }
                
                Text {
                    text: root.label + " • " + Math.round(root.currentValue * 100) + "%"
                    color: "#a6adc8"
                    font.pixelSize: 10
                    font.bold: true
                    font.family: "JetBrains Mono"
                }
            }
        }
    }
}
