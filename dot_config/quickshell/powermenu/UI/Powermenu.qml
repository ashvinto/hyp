import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../Services"

PanelWindow {
    id: root

    // Take full screen for the dimming effect, but only interact with the right side
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "powermenu"

    property bool active: false
    Component.onCompleted: active = true

    function close() { active = false; exitTimer.start() }
    Timer { id: exitTimer; interval: 350; onTriggered: Qt.quit() }

    // --- Colors ---
    readonly property color cBg: ThemeService.background
    readonly property color cCard: Qt.rgba(1, 1, 1, 0.05)
    //readonly property color cAccent: "#cba6f7"
    //readonly property color cText: "#cdd6f4"
    readonly property color cAccent: ThemeService.accent
    readonly property color cText: ThemeService.text
    readonly property color cRed: "#f38ba8"

    // 1. Background Dim
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: active ? 0.4 : 0
        Behavior on opacity { NumberAnimation { duration: 300 } }
        MouseArea { anchors.fill: parent; onClicked: root.close() }
        focus: true; Keys.onEscapePressed: root.close()
    }

    // 2. Side Panel (Slide in from right)
    Rectangle {
        id: sidePanel
        anchors { top: parent.top; bottom: parent.bottom }
        width: 120
        color: cBg
        border.width: 1; border.color: Qt.rgba(1,1,1,0.1)

        // Slide Animation
        x: active ? parent.width - width : parent.width
        Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }

        ColumnLayout {
            anchors.fill: parent; anchors.topMargin: 50; anchors.bottomMargin: 50
            spacing: 30

            // User Avatar (Small, at top)
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 60; height: 60; radius: 30; clip: true
                Image { source: "file:///home/zoro/.face"; anchors.fill: parent; fillMode: Image.PreserveAspectCrop }
            }

            Item { Layout.fillHeight: true }

            // Actions
            PowerBtn { icon: "󰌾"; label: "Lock"; color: cAccent; action: () => Quickshell.execDetached(["hyprlock"]) }
            PowerBtn { icon: "󰤄"; label: "Sleep"; color: "#89b4fa"; action: () => Quickshell.execDetached(["systemctl", "suspend"]) }
            PowerBtn { icon: "󰑓"; label: "Reboot"; color: "#fab387"; action: () => Quickshell.execDetached(["reboot"]) }
            PowerBtn { icon: "󰐥"; label: "Power"; color: cRed; action: () => Quickshell.execDetached(["shutdown", "now"]) }

            Item { Layout.fillHeight: true }

            // Close
            PowerBtn { icon: "󰅖"; label: "Close"; color: cText; action: () => root.close() }
        }
    }

    component PowerBtn: ColumnLayout {
        property string icon: ""; property string label: ""; property color color: cText; property var action: null
        spacing: 8
        Layout.alignment: Qt.AlignHCenter

        Rectangle {
            width: 70; height: 70; radius: 20; color: Qt.rgba(1,1,1,0.03)
            border.color: hover.hovered ? parent.color : "transparent"; border.width: 1

            Text { anchors.centerIn: parent; text: icon; color: parent.parent.color; font.pixelSize: 32; font.family: "Symbols Nerd Font" }
            MouseArea { anchors.fill: parent; onClicked: { if (parent.parent.action) parent.parent.action(); if (label !== "Close") root.close() } }
            HoverHandler { id: hover }

            scale: hover.hovered ? 1.05 : 1.0
            Behavior on scale { NumberAnimation { duration: 200 } }
        }
        Text { text: label; color: cText; font.pixelSize: 11; font.bold: true; Layout.alignment: Qt.AlignHCenter; opacity: hover.hovered ? 1 : 0.6 }
    }
}
