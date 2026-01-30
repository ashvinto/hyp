import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import "../Services"

PanelWindow {
    id: root

    anchors.top: true; anchors.left: true; anchors.right: true
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "qs-bar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        property bool wifiMenuOpen: false
        property real menuHeight: Math.min(NetworkService.networks.length * 48 + 70, 380)
        
        implicitHeight: wifiMenuOpen ? (menuHeight + 45) : (hoverHandler.hovered ? 42 : 1)
        exclusiveZone: (wifiMenuOpen || hoverHandler.hovered) ? 42 : 0
        Behavior on implicitHeight { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
        color: "transparent"

    HoverHandler {
        id: globalHover
        onHoveredChanged: {
            if (!hovered && wifiMenuOpen) {
                wifiMenuOpen = false
            }
        }
    }

    readonly property color cBg: "#1e1e2e"
    readonly property color cFg: "#cdd6f4"
    readonly property color cAccent: "#cba6f7"
    readonly property color cSurface: "#313244"
    readonly property color cRed: "#f38ba8"
    readonly property color cGreen: "#a6e3a1"

    // Interaction Area for Hover (Restricted to 42px)
    Item {
        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
        height: 42
        HoverHandler { id: hoverHandler }
    }

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: (hoverHandler.hovered || wifiMenuOpen) ? 0 : -42
        color: "transparent"
        Behavior on anchors.topMargin { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }

        // --- CENTER: DASHBOARD (Absolute Center) ---
        Rectangle {
            width: 50; height: 32
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 5
            radius: 16; color: cBg; border.color: cSurface; border.width: 1
            z: 10 // Ensure it's above the RowLayout if they overlap

            MouseArea {
                anchors.fill: parent
                onClicked: Quickshell.execDetached(["qs", "-c", "dashboard"])
            }

            Text {
                anchors.centerIn: parent
                text: "󰕮"
                color: cAccent
                font.pixelSize: 20
                font.family: "Symbols Nerd Font"
            }
        }

                RowLayout {

                    height: 42

                    anchors.top: parent.top

                    anchors.left: parent.left

                    anchors.right: parent.right

                    anchors.leftMargin: 15; anchors.rightMargin: 15

                    spacing: 10

        

                    // --- LEFT: ARCH, CLOCK, MUSIC & WORKSPACES ---

                    Rectangle {

                        Layout.preferredHeight: 32

                        implicitWidth: leftLayout.implicitWidth + 24

                        radius: 16; color: cBg; border.color: cSurface; border.width: 1

                        RowLayout {

                            id: leftLayout; anchors.centerIn: parent; spacing: 12

                            

                            // Arch Logo (Launcher)

                            Text {

                                text: "󰣇"

                                color: cAccent

                                font.pixelSize: 18

                                font.family: "Symbols Nerd Font"

        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: Quickshell.execDetached(["qs", "-c", "launcher"])
                        }
                    }

                    RowLayout {
                        spacing: 8
                        Text { text: ""; color: cAccent; font.pixelSize: 14 }
                        Text { text: Qt.formatTime(new Date(), "HH:mm"); color: cFg; font.bold: true; font.pixelSize: 13 }
                    }

                                        // Workspaces

                                        RowLayout {

                                            id: wsRow; spacing: 6

                                            Repeater {

                                                model: WorkspaceService.workspaces

                                                delegate: Rectangle {

                                                    width: modelData.id === WorkspaceService.activeId ? 18 : 8

                                                    height: 8; radius: 4

                                                    color: modelData.id === WorkspaceService.activeId ? cAccent : cSurface

                                                    Behavior on width { NumberAnimation { duration: 200 } }

                                                    MouseArea { 

                                                        anchors.fill: parent

                                                        onClicked: WorkspaceService.goTo(modelData.id) 

                                                    }

                                                }

                                            }

                                        }

                    

                                        RowLayout {

                                            spacing: 8

                                            visible: PlayerService.activePlayer !== null

                                            Text { text: ""; color: cAccent; font.pixelSize: 12 }

                                            Text { 

                                                text: PlayerService.activePlayer ? (PlayerService.activePlayer.trackTitle + " - " + PlayerService.activePlayer.trackArtist) : ""

                                                color: cFg; font.pixelSize: 10; elide: Text.ElideRight; Layout.maximumWidth: 120

                                            }

                                        }

                    
                }
            }

            Item { Layout.fillWidth: true } // Spacer

                        // --- RIGHT: SYSTEM TRAY & STATS ---

                        Rectangle {

                            Layout.preferredHeight: 32

                            implicitWidth: rightLayout.implicitWidth + 24

                            radius: 16; color: cBg; border.color: cSurface; border.width: 1

                            RowLayout {

                                id: rightLayout; anchors.centerIn: parent; spacing: 12

            

                                // SYSTEM TRAY (FULL)

                                RowLayout {

                                    spacing: 6

                                    Repeater {

                                        model: SystemTray.items

                                        delegate: Item {

                                            width: 18; height: 18

                                            visible: modelData.identity !== "nm-applet"

                                            Image { anchors.fill: parent; source: modelData.icon; fillMode: Image.PreserveAspectFit }

                                            MouseArea {

                                                anchors.fill: parent

                                                acceptedButtons: Qt.LeftButton | Qt.RightButton

                                                onClicked: (mouse) => {

                                                    if (mouse.button === Qt.RightButton) {

                                                        if (typeof modelData.secondaryActivate === "function") modelData.secondaryActivate()

                                                        else if (typeof modelData.contextMenu === "function") modelData.contextMenu()

                                                    } else {

                                                        modelData.activate()

                                                    }

                                                }

                                            }

                                        }

                                    }

                                }

            

                                // Clipboard (New Trigger)
                                Text {
                                    text: "󰅍"
                                    color: cAccent
                                    font.pixelSize: 14
                                    font.family: "Symbols Nerd Font"
                                    MouseArea { 
                                        anchors.fill: parent
                                        onClicked: Quickshell.execDetached(["qs", "-c", "clipboard"]) 
                                    }
                                }

            

                                // Emoji Picker (New Trigger)
                                Text {
                                    text: "󰞅"
                                    color: cAccent
                                    font.pixelSize: 14
                                    font.family: "Symbols Nerd Font"
                                    MouseArea { 
                                        anchors.fill: parent
                                        onClicked: Quickshell.execDetached(["qs", "-c", "emoji-picker"]) 
                                    }
                                }

            

                                // WiFi (Native Trigger)

                                Text {

                                    text: QuickSettingsService.wifiEnabled ? "" : "󰖪"

                                    color: QuickSettingsService.wifiEnabled ? cAccent : cRed

                                    font.pixelSize: 14

                                    MouseArea { anchors.fill: parent; onClicked: { wifiMenuOpen = !wifiMenuOpen; if(wifiMenuOpen) NetworkService.scan() } }

                                }

            

                                // Resources (CPU/RAM Small)

                                RowLayout {

                                    spacing: 6

                                    Text { text: " " + Math.round(ResourceService.cpu) + "%"; color: cFg; font.pixelSize: 9; font.bold: true }

                                    Text { text: " " + Math.round(ResourceService.ram) + "%"; color: cFg; font.pixelSize: 9; font.bold: true }

                                }

            

                                // Battery

                                RowLayout {

                                    spacing: 4

                                    Text { 

                                        text: QuickSettingsService.isCharging ? "" : ""

                                        color: QuickSettingsService.isCharging ? cGreen : cAccent

                                        font.pixelSize: 14 

                                    }

                                    Text { text: QuickSettingsService.batteryLevel + "%"; color: cFg; font.bold: true; font.pixelSize: 10 }

                                }

            

                                // Power Option

                                Rectangle {

                                    width: 24; height: 24; radius: 12; color: cSurface

                                    Text { anchors.centerIn: parent; text: ""; color: cRed; font.pixelSize: 12 }

                                    MouseArea { 

                                        anchors.fill: parent

                                        onClicked: Quickshell.execDetached(["sh", "-c", "~/.config/hypr/scripts/powermenu.sh"]) 

                                    }

                                }

                            }

                        }

            
        }

        // --- WiFi Menu ---
        Rectangle {
            anchors.top: parent.top; anchors.topMargin: 65
            anchors.right: parent.right; anchors.rightMargin: 15
            width: 320; height: wifiMenuOpen ? Math.min(NetworkService.networks.length * 48 + 70, 380) : 0
            color: cBg; radius: 16; border.color: cSurface; border.width: 1
            visible: height > 0; clip: true
            Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 15; spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Wi-Fi Networks"
                        color: cFg
                        font.bold: true
                        font.pixelSize: 15
                        Layout.fillWidth: true
                    }

                    Text {
                        text: NetworkService.scanning ? "󱓞" : "󰑐"
                        color: NetworkService.scanning ? cAccent : cFg
                        font.pixelSize: 16
                        font.family: "Symbols Nerd Font"

                        RotationAnimation on rotation {
                            running: NetworkService.scanning
                            from: 0; to: 360; duration: 1000; loops: Animation.Infinite
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: NetworkService.scan()
                        }
                    }
                }

                ListView {
                    id: wifiList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: NetworkService.networks
                    spacing: 4

                    delegate: Rectangle {
                        width: wifiList.width; height: 44; radius: 10
                        color: hoverHandlerNet.hovered ? cSurface : "transparent"

                        RowLayout {
                            anchors.fill: parent; anchors.margins: 10; spacing: 12

                            Text {
                                text: {
                                    if (modelData.signal >= 80) return "󰤨"
                                    if (modelData.signal >= 60) return "󰤥"
                                    if (modelData.signal >= 40) return "󰤢"
                                    if (modelData.signal >= 20) return "󰤟"
                                    return "󰤯"
                                }
                                color: modelData.active ? cAccent : cFg
                                font.pixelSize: 18
                                font.family: "Symbols Nerd Font"
                            }

                            ColumnLayout {
                                spacing: 0
                                Layout.fillWidth: true
                                Text {
                                    text: modelData.ssid
                                    color: cFg
                                    font.bold: modelData.active
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: modelData.security || "Open"
                                    color: Qt.rgba(cFg.r, cFg.g, cFg.b, 0.5)
                                    font.pixelSize: 9
                                    visible: text !== ""
                                }
                            }

                            Text {
                                visible: modelData.active
                                text: "󰄬"
                                color: cAccent
                                font.pixelSize: 14
                                font.family: "Symbols Nerd Font"
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                NetworkService.connect(modelData.ssid)
                                wifiMenuOpen = false
                            }
                        }
                        HoverHandler { id: hoverHandlerNet }
                    }
                }
            }
        }
    }
}
