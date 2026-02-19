import QtQuick
import QtQuick.Layouts
import Quickshell
// We assume ThemeService is available globally or via import if we symlink the services too
import "../Services"

Rectangle {
    id: root
    property string icon: ""
    signal clicked()
    
    width: 32
    height: 32
    radius: height / 2
    color: hIcon.hovered ? Qt.rgba(ThemeService.text.r, ThemeService.text.g, ThemeService.text.b, 0.1) : "transparent"
    
    Text {
        anchors.centerIn: parent
        text: root.icon
        color: ThemeService.text
        font.pixelSize: 16
        font.family: "Symbols Nerd Font"
    }
    
    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
    
    HoverHandler { id: hIcon }
    
    Behavior on color { ColorAnimation { duration: 200 } }
}
