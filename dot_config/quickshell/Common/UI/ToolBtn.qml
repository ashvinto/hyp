import QtQuick
import QtQuick.Layouts
import Quickshell
import "../Services"

Rectangle {
    id: root
    property string label: ""
    property string icon: ""
    property color btnColor: ThemeService.accent
    signal clicked()
    
    Layout.fillWidth: true
    Layout.preferredHeight: 54
    radius: 14
    color: hTool.hovered ? Qt.rgba(btnColor.r, btnColor.g, btnColor.b, 0.12) : ThemeService.surface
    border.color: hTool.hovered ? btnColor : Qt.rgba(1, 1, 1, 0.05)
    border.width: 1
    
    RowLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 12
        
        Text {
            text: root.icon
            color: root.btnColor
            font.pixelSize: 18
            font.family: "Symbols Nerd Font"
        }
        
        Text {
            text: root.label
            color: ThemeService.text
            font.bold: true
            font.pixelSize: 12
            Layout.fillWidth: true
        }
    }
    
    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
    
    HoverHandler { id: hTool }
    
    Behavior on color { ColorAnimation { duration: 200 } }
}
