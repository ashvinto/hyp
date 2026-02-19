import QtQuick
import QtQuick.Layouts
import Quickshell
import "../Services"

Rectangle {
    id: root
    property string label: ""
    property string icon: ""
    property bool active: false
    signal clicked()
    
    Layout.fillWidth: true
    height: 54
    radius: 16
    color: active ? ThemeService.accent : ThemeService.surface
    
    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10
        
        Text {
            text: root.icon
            color: root.active ? ThemeService.background : ThemeService.accent
            font.pixelSize: 18
            font.family: "Symbols Nerd Font"
        }
        
        Text {
            text: root.label
            color: root.active ? ThemeService.background : ThemeService.text
            font.bold: true
            font.pixelSize: 13
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }
    
    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
