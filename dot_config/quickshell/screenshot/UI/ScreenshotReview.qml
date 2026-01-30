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

    // Colors
    readonly property color cBg: "#1e1e2e"
    readonly property color cSurface: "#313244"
    readonly property color cText: "#cdd6f4"
    readonly property color cAccent: "#cba6f7"

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(1000, parent.width - 50)
        height: Math.min(800, parent.height - 50)
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
                text: "Screenshot Captured"
                color: cText
                font.pointSize: 18
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            // Image Preview
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "black"
                radius: 8
                clip: true

                Image {
                    anchors.fill: parent
                    source: "file://" + ScreenshotService.previewPath
                    fillMode: Image.PreserveAspectFit
                    cache: false
                }
            }

            // Action Buttons
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 20

                Button {
                    text: "📋 Copy"
                    onClicked: ScreenshotService.finishReview("both") // Copy & Save
                    background: Rectangle { color: cSurface; radius: 8; border.color: hoverHandler1.hovered ? cAccent : "transparent" }
                    contentItem: Text { text: parent.text; color: cText; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    HoverHandler { id: hoverHandler1 }
                }

                Button {
                    text: "💾 Save"
                    onClicked: ScreenshotService.finishReview("save")
                    background: Rectangle { color: cSurface; radius: 8; border.color: hoverHandler2.hovered ? cAccent : "transparent" }
                    contentItem: Text { text: parent.text; color: cText; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    HoverHandler { id: hoverHandler2 }
                }

                Button {
                    text: "✏️ Edit"
                    onClicked: ScreenshotService.finishReview("edit")
                    background: Rectangle { color: cSurface; radius: 8; border.color: hoverHandler3.hovered ? cAccent : "transparent" }
                    contentItem: Text { text: parent.text; color: cText; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    HoverHandler { id: hoverHandler3 }
                }
                
                Button {
                    text: "🗑️ Discard"
                    onClicked: Qt.quit()
                    background: Rectangle { color: hoverHandler4.hovered ? "#f38ba8" : cSurface; radius: 8; }
                    contentItem: Text { text: parent.text; color: cText; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    HoverHandler { id: hoverHandler4 }
                }
            }
        }
    }
    
    Keys.onEscapePressed: Qt.quit()
}
