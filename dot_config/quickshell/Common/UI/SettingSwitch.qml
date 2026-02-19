import QtQuick
import QtQuick.Layouts
import Quickshell
import "../Services"

Item {
    id: root
    property string label: ""
    property string desc: ""
    property string icon: ""
    property bool active: false
    signal clicked()
    
    Layout.fillWidth: true
    height: 50

    RowLayout {
        anchors.fill: parent
        spacing: 12
        
        Rectangle { 
            width: 44
            height: 44
            radius: 12
            color: ThemeService.surface
            Text { 
                anchors.centerIn: parent
                text: root.icon
                color: ThemeService.accent
                font.pixelSize: 18
                font.family: "Symbols Nerd Font" 
            } 
        }
        
        ColumnLayout { 
            spacing: 1
            Layout.fillWidth: true
            Text { 
                text: root.label
                color: ThemeService.text
                font.bold: true
                font.pixelSize: 13
            }
            Text { 
                text: root.desc
                color: ThemeService.text_dim
                font.pixelSize: 10
            } 
        }
        
        Rectangle {
            width: 44
            height: 22
            radius: 11
            color: root.active ? ThemeService.accent : Qt.rgba(1, 1, 1, 0.1)
            Rectangle { 
                x: root.active ? 24 : 2
                anchors.verticalCenter: parent.verticalCenter
                width: 18
                height: 18
                radius: 9
                color: "white"
                Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } } 
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
