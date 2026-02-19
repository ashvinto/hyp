import QtQuick
import QtQuick.Layouts
import Quickshell
import "../Services"

ColumnLayout {
    id: root
    property string label: ""
    property string value: ""
    property string icon: ""
    property color pillColor: ThemeService.accent
    
    spacing: 4
    Layout.fillWidth: true
    
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 6
        Text {
            text: root.icon
            color: root.pillColor
            font.pixelSize: 14
            font.family: "Symbols Nerd Font"
        }
        Text {
            text: root.value
            color: ThemeService.text
            font.bold: true
            font.pixelSize: 13
        }
    }
    Text {
        Layout.alignment: Qt.AlignHCenter
        text: root.label
        color: ThemeService.text_dim
        font.pixelSize: 10
        font.bold: true
        opacity: 0.7
    }
}
