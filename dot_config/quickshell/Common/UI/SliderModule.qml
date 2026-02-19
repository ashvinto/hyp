import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../Services"

RowLayout {
    id: root
    property string icon: ""
    property real value: 0
    signal moved(real val)
    signal iconClicked()
    
    Layout.fillWidth: true
    spacing: 12
    
    IconButton {
        icon: root.icon
        Layout.preferredWidth: 40
        Layout.preferredHeight: 40
        onClicked: root.iconClicked()
    }
    
    Slider {
        Layout.fillWidth: true
        value: root.value
        background: Rectangle {
            implicitHeight: 6
            radius: 3
            color: ThemeService.surface
            Rectangle {
                width: parent.parent.visualPosition * parent.width
                height: parent.height
                radius: 3
                color: ThemeService.accent
            }
        }
        handle: Rectangle {
            x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
            y: parent.topPadding + parent.availableHeight / 2 - height / 2
            width: 14
            height: 14
            radius: 7
            color: "white"
            border.color: ThemeService.accent
            border.width: 2
        }
        onMoved: root.moved(value)
    }
}
