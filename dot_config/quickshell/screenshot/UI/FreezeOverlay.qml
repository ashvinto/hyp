import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../Services"

PanelWindow {
    id: root
    
    // Fullscreen Overlay
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    
    // Ensure it stays on top
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "qs-screenshot-freeze"

    // Colors
    readonly property color cSelection: "#cba6f7" // Mauve
    readonly property color cDim: "#80000000" // Dim background

    // State
    property point startPos: "0,0"
    property point currentPos: "0,0"
    property bool selecting: false
    property string sourceFile: "/tmp/qs_freeze.png"

    // Background Image (The Frozen Screen)
    Image {
        id: bgImage
        anchors.fill: parent
        source: "file://" + root.sourceFile
        fillMode: Image.PreserveAspectFit
        cache: false // Reload on new capture
    }

    // Dim overlay (optional, makes selection pop)
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.0 // Keep 0 to see original perfectly, or 0.2 to dim
    }

    // Selection Rectangle
    Rectangle {
        id: selectionBox
        visible: root.selecting
        x: Math.min(root.startPos.x, root.currentPos.x)
        y: Math.min(root.startPos.y, root.currentPos.y)
        width: Math.abs(root.currentPos.x - root.startPos.x)
        height: Math.abs(root.currentPos.y - root.startPos.y)
        
        color: "transparent"
        border.color: cSelection
        border.width: 2
        
        // Semi-transparent fill
        Rectangle {
            anchors.fill: parent
            color: cSelection
            opacity: 0.1
        }
        
        // Dimensions Label
        Rectangle {
            anchors.top: parent.bottom
            anchors.topMargin: 5
            anchors.horizontalCenter: parent.horizontalCenter
            width: dimText.contentWidth + 10
            height: dimText.contentHeight + 6
            color: "black"
            radius: 4
            visible: parent.width > 0 && parent.height > 0
            
            Text {
                id: dimText
                anchors.centerIn: parent
                text: Math.round(parent.parent.width) + " x " + Math.round(parent.parent.height)
                color: "white"
                font.pixelSize: 12
            }
        }
    }

    // Interaction
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.CrossCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onPressed: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                Qt.quit() // Cancel
                return
            }
            root.startPos = Qt.point(mouse.x, mouse.y)
            root.currentPos = Qt.point(mouse.x, mouse.y)
            root.selecting = true
        }

        onPositionChanged: (mouse) => {
            if (root.selecting) {
                root.currentPos = Qt.point(mouse.x, mouse.y)
            }
        }

        onReleased: (mouse) => {
            if (root.selecting) {
                root.selecting = false
                finishCapture()
            }
        }
    }
    
    Keys.onEscapePressed: Qt.quit()

    function finishCapture() {
        var x = Math.min(root.startPos.x, root.currentPos.x)
        var y = Math.min(root.startPos.y, root.currentPos.y)
        var w = Math.abs(root.currentPos.x - root.startPos.x)
        var h = Math.abs(root.currentPos.y - root.startPos.y)
        
        if (w < 5 || h < 5) {
            // Clicked without dragging? Maybe treat as full screen or ignore
            Qt.quit()
            return
        }
        
        // Call Service to crop and save
        ScreenshotService.processCrop(x, y, w, h)
        Qt.quit()
    }
}
