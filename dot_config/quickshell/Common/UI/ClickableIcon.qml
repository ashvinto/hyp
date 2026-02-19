import QtQuick
import QtQuick.Controls

Item {
    id: root
    property string iconString: ""
    property color iconColor: "white"
    property real fontSize: 24
    property var clickAction: null

    implicitWidth: text.contentWidth + 10
    implicitHeight: text.contentHeight + 10

    Text {
        id: text
        anchors.centerIn: parent
        text: root.iconString
        color: mouseArea.containsMouse ? Qt.lighter(root.iconColor, 1.2) : root.iconColor
        font.pixelSize: root.fontSize
        // Assuming a nerd font is available for icons like 󰒮
        font.family: "JetBrainsMono Nerd Font"
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: if (root.clickAction) root.clickAction()
    }
}
