import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    anchors.top: true; anchors.bottom: true; anchors.left: true; anchors.right: true
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "powermenu"

    readonly property color cBg: "#11111b"
    readonly property color cSurface: "#1e1e2e"
    readonly property color cAccent: "#cba6f7"
    readonly property color cText: "#cdd6f4"
    readonly property color cRed: "#f38ba8"

    Rectangle {
        anchors.fill: parent
        color: "#cc000000" // Dark dim

        MouseArea { anchors.fill: parent; onClicked: Qt.quit() }
        focus: true
        Keys.onEscapePressed: Qt.quit()

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 40

            Text {
                text: "Goodbye, " + Quickshell.env("USER") + "!"
                color: cText
                font.pixelSize: 32; font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            RowLayout {
                spacing: 20
                Layout.alignment: Qt.AlignHCenter

                PowermenuButton { icon: "󰌾"; label: "Lock"; color: cAccent; action: () => Quickshell.execDetached(["qs", "-c", "lockscreen"]) }
                PowermenuButton { icon: "󰍃"; label: "Exit"; color: cAccent; action: () => Quickshell.execDetached(["hyprctl", "dispatch", "exit"]) }
                PowermenuButton { icon: "󰤄"; label: "Sleep"; color: "#89b4fa"; action: () => Quickshell.execDetached(["systemctl", "suspend"]) }
                PowermenuButton { icon: "󰑓"; label: "Reboot"; color: "#fab387"; action: () => Quickshell.execDetached(["reboot"]) }
                PowermenuButton { icon: "󰐥"; label: "Power"; color: cRed; action: () => Quickshell.execDetached(["shutdown", "now"]) }
            }
        }
    }

    component PowermenuButton: ColumnLayout {
        property string icon: ""; property string label: ""; property color color: cAccent; property var action: null
        spacing: 10
        Rectangle {
            width: 100; height: 100; radius: 50; color: cSurface; border.color: mouseArea.containsMouse ? parent.color : cSurface; border.width: 3
            Behavior on border.color { ColorAnimation { duration: 200 } }
            Text { anchors.centerIn: parent; text: icon; color: parent.parent.color; font.pixelSize: 42 }
            MouseArea {
                id: mouseArea; anchors.fill: parent; hoverEnabled: true
                onClicked: { parent.parent.action(); Qt.quit() }
            }
        }
        Text { text: label; color: cText; font.bold: true; font.pixelSize: 14; Layout.alignment: Qt.AlignHCenter }
    }
}
