import QtQuick
import QtQuick.Layouts
import Quickshell
import "../Services"

Rectangle {
    id: root
    property string icon: ""
    property string label: ""
    property bool active: false
    signal clicked()
    
    Layout.fillWidth: true
    height: 40
    radius: 10
    color: active ? Qt.rgba(ThemeService.accent.r, ThemeService.accent.g, ThemeService.accent.b, 0.12) : "transparent"
    
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 15
        spacing: 10
        Text { 
            text: root.icon
            color: active ? ThemeService.accent : ThemeService.text
            font.pixelSize: 16
            font.family: "Symbols Nerd Font" 
        }
        Text { 
            text: root.label
            color: active ? ThemeService.text : ThemeService.text_dim
            font.bold: active
            font.pixelSize: 12 
        }
    }
    MouseArea { 
        anchors.fill: parent
        onClicked: root.clicked() 
    }
}
