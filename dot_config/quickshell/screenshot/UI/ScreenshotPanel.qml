import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
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

    MouseArea {
        anchors.fill: parent
        onClicked: Qt.quit()
        z: -1
    }

    // Colors
    readonly property color cBg: "#1e1e2e"
    readonly property color cSurface: "#313244"
    readonly property color cText: "#cdd6f4"
    readonly property color cAccent: "#cba6f7"

    Rectangle {
        anchors.centerIn: parent
        width: 500
        height: 350
        color: cBg
        radius: 16
        border.color: cSurface
        border.width: 2
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20

            Text {
                text: "Take Screenshot"
                color: cText
                font.pointSize: 18
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            // Mode Buttons
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                spacing: 15

                Repeater {
                    model: [
                        { name: "Region", icon: "✂️", mode: "region" },
                        { name: "Fullscreen", icon: "🖥️", mode: "fullscreen" },
                        { name: "Window", icon: "🪟", mode: "window" },
                        { name: "Freeze", icon: "❄️", mode: "freeze" }
                    ]
                    
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: hoverHandler.hovered ? cSurface : "transparent"
                        radius: 12
                        border.color: hoverHandler.hovered ? cAccent : cSurface
                        border.width: 2

                        HoverHandler { id: hoverHandler }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: ScreenshotService.capture(modelData.mode)
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 5
                            Text {
                                text: modelData.icon
                                font.pixelSize: 32
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: modelData.name
                                color: cText
                                font.bold: true
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                }
            }

            // Options
            GridLayout {
                columns: 2
                Layout.alignment: Qt.AlignHCenter
                rowSpacing: 10
                columnSpacing: 20

                CheckBox {
                    text: "Copy to Clipboard"
                    checked: ScreenshotService.copyToClipboard
                    onCheckedChanged: ScreenshotService.copyToClipboard = checked
                    
                    contentItem: Text {
                        text: parent.text
                        color: cText
                        leftPadding: parent.indicator.width + parent.spacing
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                CheckBox {
                    text: "Save to File"
                    checked: ScreenshotService.saveToFile
                    onCheckedChanged: ScreenshotService.saveToFile = checked
                    contentItem: Text { text: parent.text; color: cText; leftPadding: parent.indicator.width + parent.spacing; verticalAlignment: Text.AlignVCenter }
                }

                CheckBox {
                    text: "Edit (Swappy)"
                    checked: ScreenshotService.editAfter
                    onCheckedChanged: ScreenshotService.editAfter = checked
                    contentItem: Text { text: parent.text; color: cText; leftPadding: parent.indicator.width + parent.spacing; verticalAlignment: Text.AlignVCenter }
                }
                
                RowLayout {
                    Text { text: "Delay (s):"; color: cText }
                    SpinBox {
                        from: 0; to: 10
                        value: ScreenshotService.delay
                        onValueChanged: ScreenshotService.delay = value
                        implicitWidth: 100
                    }
                }
            }
        }
    }
    
    // Keybinds
    Item {
        focus: true
        Keys.onEscapePressed: Qt.quit()
    }
}
