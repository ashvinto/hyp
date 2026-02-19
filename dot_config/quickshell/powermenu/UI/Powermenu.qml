import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../Services"

PanelWindow {
    id: root

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "powermenu"

    property bool active: false
    Component.onCompleted: active = true

    function close() { 
        active = false; 
        exitTimer.start() 
    }
    Timer { id: exitTimer; interval: 400; onTriggered: Qt.quit() }

    // --- Colors ---
    readonly property color cBg: ThemeService.background
    readonly property color cSurface: ThemeService.surface
    readonly property color cBorder: ThemeService.surface_variant
    readonly property color cAccent: ThemeService.accent
    readonly property color cText: ThemeService.text
    readonly property color cDim: ThemeService.text_dim
    readonly property color cRed: ThemeService.error

    // 1. Background Dim & Blur
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: active ? 0.6 : 0
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
    }

    MouseArea { 
        anchors.fill: parent
        onClicked: root.close()
    }

    // 2. Central Power Card
    Rectangle {
        id: powerCard
        anchors.centerIn: parent
        width: 620
        height: 560
        radius: 40
        color: cBg
        border.width: 1
        border.color: cBorder
        clip: true

        scale: active ? 1.0 : 0.7
        opacity: active ? 1.0 : 0
        rotation: active ? 0 : -3
        
        Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        Behavior on rotation { NumberAnimation { duration: 600; easing.type: Easing.OutBack } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 45
            spacing: 35

            // User Info Header
            RowLayout {
                id: header
                Layout.fillWidth: true
                spacing: 20
                opacity: active ? 1.0 : 0
                Layout.topMargin: active ? 0 : -20
                
                Behavior on opacity { 
                    SequentialAnimation {
                        PauseAnimation { duration: 100 }
                        NumberAnimation { duration: 500 }
                    }
                }
                Behavior on Layout.topMargin { 
                    SequentialAnimation {
                        PauseAnimation { duration: 100 }
                        NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                    }
                }

                Rectangle {
                    width: 80; height: 80; radius: 40
                    color: cAccent
                    clip: true
                    
                    Image {
                        source: (typeof ConfigService !== "undefined") ? ConfigService.profileIcon : "file:///home/zoro/.face"
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        onStatusChanged: if (status == Image.Error) fallbackIcon.visible = true
                    }
                    Text {
                        id: fallbackIcon
                        anchors.centerIn: parent
                        text: SystemService.user[0].toUpperCase()
                        font.bold: true; font.pixelSize: 32; color: "black"
                        visible: false
                    }
                    
                    // Profile Glow
                    Rectangle {
                        anchors.fill: parent; radius: 40; color: "transparent"
                        border.color: cAccent; border.width: 2; opacity: 0.5
                    }
                }

                ColumnLayout {
                    spacing: 4
                    Text {
                        text: SystemService.greeting + ", " + SystemService.user
                        color: cText
                        font.pixelSize: 26; font.bold: true
                    }
                    Text {
                        text: "System Uptime: " + SystemService.uptime
                        color: cDim
                        font.pixelSize: 14
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                // Close button top right
                Rectangle {
                    width: 44; height: 44; radius: 22
                    color: closeHover.hovered ? cAccent : cSurface
                    border.color: closeHover.hovered ? "transparent" : cBorder
                    
                    Text { 
                        anchors.centerIn: parent
                        text: "󰅖"
                        color: closeHover.hovered ? "black" : cText
                        font.pixelSize: 20
                        font.family: "Symbols Nerd Font"
                    }
                    
                    MouseArea { id: closeArea; anchors.fill: parent; onClicked: root.close() }
                    HoverHandler { id: closeHover }
                    
                    Behavior on color { ColorAnimation { duration: 200 } }
                    scale: closeHover.hovered ? 1.1 : 1.0
                    Behavior on scale { NumberAnimation { duration: 200 } }
                }
            }

            Rectangle { 
                Layout.fillWidth: true; height: 1; color: cBorder; opacity: 0.3 
                scale: active ? 1.0 : 0
                Behavior on scale { 
                    SequentialAnimation {
                        PauseAnimation { duration: 200 }
                        NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
                    }
                }
            }

            // Grid of Actions
            GridLayout {
                columns: 3
                rowSpacing: 30
                columnSpacing: 30
                Layout.alignment: Qt.AlignHCenter
                Layout.fillHeight: true

                PowerBtn { 
                    index: 0; icon: "󰌾"; label: "Lock"; btnColor: cAccent; active: root.active; closeAction: root.close
                    action: () => Quickshell.execDetached(["/home/zoro/.config/hypr/scripts/lock.sh"]) 
                }
                PowerBtn { 
                    index: 1; icon: "󰍃"; label: "Logout"; btnColor: "#fab387"; active: root.active; closeAction: root.close
                    action: () => Quickshell.execDetached(["hyprctl", "dispatch", "exit"]) 
                }
                PowerBtn { 
                    index: 2; icon: "󰤄"; label: "Sleep"; btnColor: "#89b4fa"; active: root.active; closeAction: root.close
                    action: () => Quickshell.execDetached(["systemctl", "suspend"]) 
                }
                PowerBtn { 
                    index: 3; icon: "󰒲"; label: "Hibernate"; btnColor: "#b4befe"; active: root.active; closeAction: root.close
                    action: () => Quickshell.execDetached(["systemctl", "hibernate"]) 
                }
                PowerBtn { 
                    index: 4; icon: "󰑓"; label: "Reboot"; btnColor: "#a6e3a1"; active: root.active; closeAction: root.close
                    action: () => Quickshell.execDetached(["reboot"]) 
                }
                PowerBtn { 
                    index: 5; icon: "󰐥"; label: "Shutdown"; btnColor: cRed; active: root.active; closeAction: root.close
                    action: () => Quickshell.execDetached(["shutdown", "now"]) 
                }
            }
        }
    }
}
