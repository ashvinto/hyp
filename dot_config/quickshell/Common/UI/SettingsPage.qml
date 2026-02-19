import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../Services"

ScrollView {
    id: root
    property string title: ""
    default property alias content: mainCol.data
    Layout.fillWidth: true
    Layout.fillHeight: true
    
    contentWidth: availableWidth
    contentHeight: mainCol.implicitHeight + 60
    clip: true
    
    ScrollBar.vertical: ScrollBar {
        width: 6
        policy: ScrollBar.AsNeeded
        active: true
        contentItem: Rectangle {
            radius: 3
            color: Qt.rgba(ThemeService.accent.r, ThemeService.accent.g, ThemeService.accent.b, 0.3)
        }
    }

    ColumnLayout {
        id: mainCol
        width: parent.width - 60
        spacing: 25
        anchors.margins: 30
        anchors.left: parent.left
        anchors.top: parent.top
        
        Text {
            text: root.title
            color: ThemeService.accent
            font.bold: true
            font.pixelSize: 11
            font.letterSpacing: 1 
        }
    }
}
