import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../Services"

PanelWindow {
    id: root

    // Positioning: Bottom Left floating
    anchors.bottom: true
    anchors.left: true
    
    // Fixed window geometry to avoid crashes
    WlrLayershell.margins.left: 0
    WlrLayershell.margins.bottom: 0
    WlrLayershell.exclusiveZone: -1
    
    width: 400
    height: 160
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "music-player"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    readonly property color cBg: ThemeService.background
    readonly property color cSurface: ThemeService.surface
    readonly property color cAccent: ThemeService.accent
    readonly property color cText: ThemeService.text
    readonly property color cDim: ThemeService.text_dim
    
    Rectangle {
        id: bg
        width: 380
        height: 140
        
        // Slide Animation:
        // Always visible at x=20 when running.
        // Shell Manager handles the process lifecycle (hiding/showing).
        x: 20
        NumberAnimation on x { from: -400; to: 20; duration: 300; easing.type: Easing.OutCubic; running: true }

        radius: 20
        color: Qt.rgba(cBg.r, cBg.g, cBg.b, 0.90)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.1)
        clip: true

        HoverHandler { id: hoverHandler }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0,0,0,0.4)
            shadowBlur: 15
            shadowVerticalOffset: 5
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 15

            // Album Art
            Rectangle {
                Layout.preferredWidth: 110
                Layout.fillHeight: true
                radius: 12
                color: cSurface
                clip: true
                
                Image {
                    anchors.fill: parent
                    source: MprisService.artUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    
                    // Fallback icon
                    Rectangle {
                        anchors.fill: parent
                        color: cSurface
                        visible: parent.status !== Image.Ready
                        Text {
                            anchors.centerIn: parent
                            text: ""
                            color: cDim
                            font.pixelSize: 40
                            font.family: "Symbols Nerd Font"
                        }
                    }
                }
            }

            // Controls & Info
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 5

                // Info
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: MprisService.title
                        color: cText
                        font.bold: true
                        font.pixelSize: 14
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: MprisService.artist || "Unknown Artist"
                        color: cAccent
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
                
                Item { Layout.fillHeight: true }

                // Progress Bar (Interactive Slider)
                Slider {
                    id: progressSlider
                    Layout.fillWidth: true
                    height: 10
                    from: 0
                    to: MprisService.length > 0 ? MprisService.length : 1
                    value: MprisService.position

                    // Only update position when user is NOT dragging
                    // This prevents the slider from jumping back while dragging
                    onMoved: MprisService.seek(value)
                    
                    background: Rectangle {
                        x: progressSlider.leftPadding
                        y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                        implicitWidth: 200
                        implicitHeight: 4
                        width: progressSlider.availableWidth
                        height: implicitHeight
                        radius: 2
                        color: Qt.rgba(cSurface.r, cSurface.g, cSurface.b, 0.5)

                        Rectangle {
                            width: progressSlider.visualPosition * parent.width
                            height: parent.height
                            color: cAccent
                            radius: 2
                        }
                    }

                    handle: Rectangle {
                        x: progressSlider.leftPadding + progressSlider.visualPosition * (progressSlider.availableWidth - width)
                        y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                        implicitWidth: 10
                        implicitHeight: 10
                        radius: 5
                        color: cAccent
                        visible: progressSlider.hovered || progressSlider.pressed
                    }
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: formatTime(MprisService.position)
                        color: cDim
                        font.pixelSize: 10
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: formatTime(MprisService.length)
                        color: cDim
                        font.pixelSize: 10
                    }
                }

                // Controls
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 20
                    
                    IconButton { icon: "󰒮"; onClicked: MprisService.prev() }
                    
                    Rectangle {
                        width: 36; height: 36; radius: 18
                        color: cAccent
                        Text {
                            anchors.centerIn: parent
                            text: (MprisService.status === "Playing") ? "󰏤" : "󰐊"
                            color: cBg
                            font.pixelSize: 16
                            font.family: "Symbols Nerd Font"
                        }
                        MouseArea { 
                            anchors.fill: parent
                            onClicked: {
                                MprisService.togglePlay()
                                // Optimistic update (will be corrected by poller)
                                if (MprisService.status === "Playing") MprisService.status = "Paused"
                                else MprisService.status = "Playing"
                            }
                        }
                    }
                    
                    IconButton { icon: "󰒭"; onClicked: MprisService.next() }
                }
            }
        }
    }

    component IconButton: Rectangle {
        property string icon: ""
        signal clicked()
        width: 32; height: 32; radius: 16; color: "transparent"
        Text { 
            anchors.centerIn: parent; text: icon; color: cText; 
            font.pixelSize: 20; font.family: "Symbols Nerd Font" 
        }
        MouseArea { 
            anchors.fill: parent; hoverEnabled: true
            onEntered: parent.color = Qt.rgba(1,1,1,0.1)
            onExited: parent.color = "transparent"
            onClicked: parent.clicked() 
        }
    }

    function formatTime(seconds) {
        if (!seconds || isNaN(seconds)) return "0:00"
        var m = Math.floor(seconds / 60)
        var s = Math.floor(seconds % 60)
        return m + ":" + (s < 10 ? "0" : "") + s
    }
}
