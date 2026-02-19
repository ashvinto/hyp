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
    
    implicitHeight: 200
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "osd"

    color: "transparent"
    
    property bool visible_state: false
    property string currentIcon: "󰕾"
    property real currentValue: 0
    property string label: "Volume"
    property string activeType: ""

    // Use local singleton
    readonly property color cBg: ThemeService.background
    readonly property color cSurface: ThemeService.surface
    readonly property color cAccent: ThemeService.accent
    readonly property color cText: ThemeService.text
    readonly property color cDim: ThemeService.text_dim

    // Mix background with surface for better visibility
    readonly property color cGlass: Qt.alpha(Qt.tint(cBg, Qt.rgba(cSurface.r, cSurface.g, cSurface.b, 0.2)), 0.95)

    Timer {
        id: hideTimer
        interval: 2500
        onTriggered: visible_state = false
    }

    // Auto-quit only if not visible for a while to keep the process warm
    Timer {
        id: quitTimer
        interval: 8000
        running: !visible_state
        onTriggered: Qt.quit()
    }

    function showVolume() {
        if (activeType !== "volume" && visible_state) return; 
        activeType = "volume"
        currentIcon = VolumeService.muted ? "󰝟" : "󰕾"
        currentValue = VolumeService.volume / 100
        label = "Volume"
        visible_state = true
        hideTimer.restart()
    }

    function showBrightness() {
        if (activeType !== "brightness" && visible_state) return; 
        activeType = "brightness"
        currentIcon = "󰃠"
        currentValue = BrightnessService.brightness / 100
        label = "Brightness"
        visible_state = true
        hideTimer.restart()
    }

    Connections {
        target: VolumeService
        function onChanged() { showVolume() }
    }

    Connections {
        target: BrightnessService
        function onChanged() { showBrightness() }
    }
    
    Component.onCompleted: {
        var envType = Quickshell.env("QS_OSD_TYPE")
        if (envType === "brightness") {
            showBrightness()
        } else {
            showVolume()
        }
    }

    Item {
        id: container
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 100
        width: 300
        height: 60
        
        opacity: visible_state ? 1.0 : 0.0
        scale: visible_state ? 1.0 : 0.8
        
        // Vertical slide animation
        anchors.horizontalCenterOffset: 0
        transform: Translate { 
            y: visible_state ? 0 : 20 
            Behavior on y { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
        }

        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }

        // Main Glass Pill
        Rectangle {
            id: pill
            anchors.fill: parent
            color: cGlass
            radius: 30
            border.color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.4)
            border.width: 1
            clip: true

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 15

                // Icon with glow
                Item {
                    width: 32; height: 32
                    Text {
                        anchors.centerIn: parent
                        text: root.currentIcon
                        color: cAccent
                        font.pixelSize: 24
                        font.family: "Symbols Nerd Font"
                        
                        // Icon bounce animation on value change
                        scale: root.visible_state ? 1.0 : 0.5
                        Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
                    }
                }

                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true
                    
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: root.label
                            color: cText
                            font.pixelSize: 12
                            font.bold: true
                            font.family: "JetBrains Mono"
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: Math.round(root.currentValue * 100) + "%"
                            color: cAccent
                            font.pixelSize: 12
                            font.bold: true
                            font.family: "JetBrains Mono"
                        }
                    }

                    // Progress Bar
                    Rectangle {
                        id: track
                        Layout.fillWidth: true
                        height: 8
                        radius: 4
                        color: Qt.rgba(cText.r, cText.g, cText.b, 0.1)
                        
                        Rectangle {
                            id: bar
                            width: parent.width * Math.min(Math.max(root.currentValue, 0), 1)
                            height: parent.height
                            radius: 4
                            color: cAccent
                            
                            // Morphing glow effect
                            Rectangle {
                                anchors.fill: parent
                                radius: 4
                                color: cAccent
                                opacity: 0.3
                                visible: root.visible_state
                            }

                            Behavior on width { 
                                NumberAnimation { 
                                    duration: 300; 
                                    easing.type: Easing.OutQuint 
                                } 
                            }
                        }
                    }
                }
            }
        }

        // External Glow
        MultiEffect {
            anchors.fill: pill
            source: pill
            blurEnabled: true
            blur: 0.2
            brightness: 0.1
            z: -1
            opacity: 0.5
        }
    }
}
