import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../Services"

ColumnLayout {
    id: root
    property string label: ""
    property string icon: ""
    property real value: 0
    signal moved(real v)
    
    spacing: 8
    Layout.fillWidth: true
    
    RowLayout {
        spacing: 10
        Text { 
            text: root.icon
            color: ThemeService.accent
            font.pixelSize: 16
            font.family: "Symbols Nerd Font" 
        }
        Text { 
            text: root.label
            color: ThemeService.text
            font.bold: true
            font.pixelSize: 12
            Layout.fillWidth: true 
        }
        Text { 
            text: {
                if (label.includes("Rounding")) return Math.round(root.value * 30)
                if (label.includes("Inner")) return Math.round(root.value * 20)
                if (label.includes("Outer")) return Math.round(root.value * 40)
                return Math.round(root.value * 100) + "%"
            }
            color: ThemeService.accent
            font.bold: true
            font.pixelSize: 10
        }
    }
    
    Slider {
        Layout.fillWidth: true
        Layout.preferredHeight: 20
        from: 0
        to: 1
        value: root.value
        onMoved: root.moved(value)
        
        background: Rectangle { 
            y: (parent.height - height) / 2
            height: 4
            radius: 2
            color: Qt.rgba(1, 1, 1, 0.08)
            width: parent.width
            Rectangle { 
                width: parent.parent.visualPosition * parent.width
                height: parent.height
                color: ThemeService.accent
                radius: 2
            } 
        }
        handle: Rectangle { 
            x: parent.visualPosition * (parent.width - width)
            y: (parent.height - height) / 2
            width: 16
            height: 16
            radius: 8
            color: "white"
            border.width: 3
            border.color: ThemeService.accent 
        }
    }
}
