import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import "../Services"

PanelWindow {
    id: root

    anchors.top: true
    anchors.left: true
    anchors.right: true
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "qs-bar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    property bool wifiMenuOpen: false
    property bool powerMenuOpen: false
    property var wifiConnectingData: null // { ssid: string, security: string, method: string }
    
    // Geometric constants
    readonly property int menuWidth: 300
    readonly property int rowHeight: 40
    readonly property int activeRowHeight: 60
    readonly property int hPadding: 16

    property real wifiMenuHeight: {
        var h = 0
        // Header + Ethernet
        h += 60
        // Active WiFi Section
        var activeNets = NetworkService.networks.filter(function(n) { return n.active || n.ssid === NetworkService.activeWifiSsid })
        if (activeNets.length > 0) h += 80
        // Available Networks Section
        var availNets = NetworkService.networks.filter(function(n) { return !n.active && n.ssid !== NetworkService.activeWifiSsid })
        h += Math.min(availNets.length * rowHeight + 40, 350)
        // Footer (Networking, WiFi toggles, editor)
        h += 140
        // Password Area
        if (wifiConnectingData !== null) {
            h += wifiConnectingData.method === "enterprise" ? 100 : 60
        }
        return h + 40
    }
    
    property real powerMenuHeight: 280

    implicitHeight: (wifiMenuOpen || powerMenuOpen) ? 850 : (hoverHandler.hovered ? 42 : 1)
    exclusiveZone: (wifiMenuOpen || powerMenuOpen || hoverHandler.hovered) ? 42 : 0
    
    Behavior on implicitHeight { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
    color: "transparent"

    HoverHandler {
        id: globalHover
        onHoveredChanged: {
            if (!hovered) {
                wifiMenuOpen = false
                powerMenuOpen = false
                wifiConnectingData = null
            }
        }
    }

    readonly property color cBg: "#1e1e2e"
    readonly property color cFg: "#cdd6f4"
    readonly property color cAccent: "#cba6f7"
    readonly property color cSurface: "#313244"
    readonly property color cRed: "#f38ba8"
    readonly property color cGreen: "#a6e3a1"
    readonly property color cDim: Qt.rgba(0.8, 0.8, 0.9, 0.4)

    Item {
        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
        height: 42
        HoverHandler { id: hoverHandler }
    }

    Rectangle {
        id: barContainer
        anchors.fill: parent
        anchors.topMargin: (hoverHandler.hovered || wifiMenuOpen || powerMenuOpen) ? 0 : -42
        color: "transparent"
        Behavior on anchors.topMargin { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

        // --- DASHBOARD ---
        Rectangle {
            width: 50; height: 32
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top; anchors.topMargin: 5
            radius: 16; color: cBg; border.color: cSurface; border.width: 1
            z: 10 
            Text { anchors.centerIn: parent; text: "󰕮"; color: cAccent; font.pixelSize: 20; font.family: "Symbols Nerd Font" }
            MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["qs", "-c", "dashboard"]) }
        }

        RowLayout {
            height: 42
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 15; anchors.rightMargin: 15
            spacing: 10

            // --- LEFT ---
            Rectangle {
                Layout.preferredHeight: 32
                implicitWidth: leftLayout.implicitWidth + 24
                radius: 16; color: cBg; border.color: cSurface; border.width: 1
                RowLayout {
                    id: leftLayout; anchors.centerIn: parent; spacing: 12
                    Text { text: "󰣇"; color: cAccent; font.pixelSize: 18; font.family: "Symbols Nerd Font"; MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["qs", "-c", "launcher"]) } }
                    RowLayout {
                        spacing: 8
                        Text { text: ""; color: cAccent; font.pixelSize: 14 }
                        Text { text: Qt.formatTime(new Date(), "HH:mm"); color: cFg; font.bold: true; font.pixelSize: 13 }
                    }
                    RowLayout {
                        id: wsRow; spacing: 6
                        Repeater {
                            model: WorkspaceService.workspaces
                            delegate: Rectangle {
                                width: modelData.id === WorkspaceService.activeId ? 18 : 8
                                height: 8; radius: 4
                                color: modelData.id === WorkspaceService.activeId ? cAccent : cSurface
                                Behavior on width { NumberAnimation { duration: 200 } }
                                MouseArea { anchors.fill: parent; onClicked: WorkspaceService.goTo(modelData.id) }
                            }
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true } 

            // --- RIGHT ---
            Rectangle {
                Layout.preferredHeight: 32
                implicitWidth: rightLayout.implicitWidth + 24
                radius: 16; color: cBg; border.color: cSurface; border.width: 1

                RowLayout {
                    id: rightLayout; anchors.centerIn: parent; spacing: 12

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
                                        } else { modelData.activate() }
                                    }
                                }
                            }
                        }
                    }

                    Text { text: "󰅍"; color: cAccent; font.pixelSize: 14; font.family: "Symbols Nerd Font"; MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["qs", "-c", "clipboard"]) } }
                    Text { text: "󰞅"; color: cAccent; font.pixelSize: 14; font.family: "Symbols Nerd Font"; MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["qs", "-c", "emoji-picker"]) } }

                    Rectangle {
                        width: 26; height: 26; radius: 13
                        color: wifiMenuOpen ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.15) : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: QuickSettingsService.wifiEnabled ? "" : "󰖪"
                            color: QuickSettingsService.wifiEnabled ? (wifiMenuOpen ? cAccent : cFg) : cRed
                            font.pixelSize: 14; font.family: "Symbols Nerd Font"
                        }
                        MouseArea { 
                            anchors.fill: parent
                            onClicked: { wifiMenuOpen = !wifiMenuOpen; if (wifiMenuOpen) { powerMenuOpen = false; NetworkService.scan() } }
                        }
                    }

                    RowLayout {
                        spacing: 6
                        Text { text: " " + Math.round(ResourceService.cpu) + "%"; color: cFg; font.pixelSize: 9; font.bold: true }
                        Text { text: " " + Math.round(ResourceService.ram) + "%"; color: cFg; font.pixelSize: 9; font.bold: true }
                    }

                    RowLayout {
                        spacing: 4
                        Text { 
                            text: QuickSettingsService.isCharging ? "" : ""
                            color: QuickSettingsService.isCharging ? cGreen : cAccent; font.pixelSize: 14 
                        }
                        Text { text: QuickSettingsService.batteryLevel + "%"; color: cFg; font.bold: true; font.pixelSize: 10 }
                    }

                    Rectangle {
                        width: 26; height: 26; radius: 13
                        readonly property color activeColor:
                            PowerProfileService.activeProfile === "performance" ? cRed :
                            PowerProfileService.activeProfile === "power-saver" ? cGreen : cAccent

                        color: {
                            var color = PowerProfileService.activeProfile === "performance" ? cRed :
                                       PowerProfileService.activeProfile === "power-saver" ? cGreen : cAccent;
                            powerMenuOpen ? Qt.rgba(color.r, color.g, color.b, 0.15) : "transparent"
                        }
                        Text {
                            anchors.centerIn: parent
                            text: {
                                if (PowerProfileService.activeProfile === "performance") return "󰓅"
                                if (PowerProfileService.activeProfile === "power-saver") return "󰾆"
                                return "󰾅"
                            }
                            color: {
                                var color = PowerProfileService.activeProfile === "performance" ? cRed :
                                           PowerProfileService.activeProfile === "power-saver" ? cGreen : cAccent;
                                powerMenuOpen ? color : (PowerProfileService.activeProfile !== "balanced" ? color : cFg)
                            }
                            font.pixelSize: 16; font.family: "Symbols Nerd Font"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: { powerMenuOpen = !powerMenuOpen; if (powerMenuOpen) wifiMenuOpen = false }
                        }
                    }

                    // Power Button
                    Rectangle {
                        width: 24; height: 24; radius: 12; color: cSurface
                        Text { anchors.centerIn: parent; text: ""; color: cRed; font.pixelSize: 12 }
                        MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["sh", "-c", "~/.config/hypr/scripts/powermenu.sh"]) }
                    }
                }
            }
        }

        // --- Structured Network Island ---
        Rectangle {
            id: wifiIsland
            anchors.top: parent.top; anchors.topMargin: wifiMenuOpen ? 52 : 40
            anchors.right: parent.right; anchors.rightMargin: 15
            width: menuWidth; height: wifiMenuOpen ? wifiMenuHeight : 0
            color: Qt.rgba(0.12, 0.12, 0.18, 0.98)
            radius: 20; border.color: Qt.rgba(1, 1, 1, 0.1); border.width: 1
            visible: opacity > 0; opacity: wifiMenuOpen ? 1 : 0
            
            Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
            Behavior on anchors.topMargin { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
            Behavior on opacity { NumberAnimation { duration: 300 } }

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 0; spacing: 0
                
                // 1. Ethernet Section
                ColumnLayout {
                    Layout.fillWidth: true; Layout.margins: 12; spacing: 8
                    Text { text: "ETHERNET NETWORKS"; color: cDim; font.bold: true; font.pixelSize: 10 }
                    RowLayout {
                        Layout.fillWidth: true; height: 30
                        Text { text: "󰈀"; color: NetworkService.ethernetStatus === "Connected" ? cGreen : cDim; font.pixelSize: 16; font.family: "Symbols Nerd Font" }
                        Text { text: "Ethernet"; color: cFg; font.pixelSize: 13; Layout.fillWidth: true }
                        Text { text: NetworkService.ethernetStatus; color: NetworkService.ethernetStatus === "Connected" ? cGreen : cDim; font.pixelSize: 11; font.bold: true }
                    }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1, 1, 1, 0.05) }

                // 2. Wi-Fi Section (Active Block)
                ColumnLayout {
                    Layout.fillWidth: true; Layout.margins: 12; spacing: 8
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "WI-FI NETWORKS"; color: cDim; font.bold: true; font.pixelSize: 10; Layout.fillWidth: true }
                        
                        // Scan Button
                        RowLayout {
                            spacing: 6
                            Text {
                                id: scanIcon
                                text: "󰑐"
                                color: cAccent
                                font.pixelSize: 12
                                font.family: "Symbols Nerd Font"
                                transformOrigin: Item.Center
                                RotationAnimation on rotation {
                                    running: NetworkService.scanning
                                    from: 0; to: 360; duration: 1000; loops: Animation.Infinite
                                }
                            }
                            Text {
                                text: NetworkService.scanning ? "Scanning..." : "Scan"
                                color: cAccent
                                font.pixelSize: 10
                                font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: NetworkService.scan()
                            }
                        }
                    }
                    
                    // Show currently connected network
                    Repeater {
                        model: NetworkService.networks.filter(function(n) { return n.active || n.ssid === NetworkService.activeWifiSsid })
                        delegate: Rectangle {
                            Layout.fillWidth: true; height: activeRowHeight; radius: 12; color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.1)
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 12; spacing: 12
                                Text { text: "󰄬"; color: cAccent; font.pixelSize: 16; font.family: "Symbols Nerd Font" }
                                ColumnLayout {
                                    spacing: 2; Layout.fillWidth: true
                                    Text { text: modelData.ssid; color: cFg; font.bold: true; font.pixelSize: 13; elide: Text.ElideRight }
                                    Text { text: "Connected"; color: cAccent; font.pixelSize: 10 }
                                }
                                Button {
                                    text: "Disconnect"
                                    onClicked: NetworkService.disconnect()
                                    background: Rectangle { color: parent.hovered ? cRed : "transparent"; radius: 6; border.color: cRed; border.width: 1 }
                                    contentItem: Text { text: parent.text; color: parent.hovered ? cBg : cRed; font.pixelSize: 10; font.bold: true; padding: 4 }
                                }
                            }
                        }
                    }
                }

                // 3. Available Networks List
                ColumnLayout {
                    Layout.fillWidth: true; Layout.leftMargin: 12; Layout.rightMargin: 12; Layout.bottomMargin: 12; spacing: 8
                    
                    ListView {
                        id: wifiList; Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 4
                        model: NetworkService.networks.filter(function(n) { return !n.active && n.ssid !== NetworkService.activeWifiSsid })
                        
                        Text {
                            anchors.centerIn: parent; text: "No networks found"; color: cDim; font.pixelSize: 12
                            visible: wifiList.count === 0 && !NetworkService.scanning
                        }
                        Text {
                            anchors.centerIn: parent; text: "Scanning..."; color: cAccent; font.pixelSize: 12
                            visible: wifiList.count === 0 && NetworkService.scanning
                        }

                        delegate: Rectangle {
                            width: wifiList.width; height: rowHeight; radius: 8
                            color: hoverAvail.hovered ? cSurface : "transparent"
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 12; spacing: 12
                                Item { width: 16; height: 16 } 
                                Text { text: modelData.ssid; color: cFg; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true }
                                RowLayout {
                                    spacing: 6
                                    Text { 
                                        visible: modelData.security !== "" && modelData.security !== "--"
                                        text: "󰌾"; color: cDim; font.pixelSize: 12; font.family: "Symbols Nerd Font" 
                                    }
                                    Text {
                                        text: {
                                            if (modelData.signal >= 80) return "󰤨"; if (modelData.signal >= 60) return "󰤥"
                                            if (modelData.signal >= 40) return "󰤢"; if (modelData.signal >= 20) return "󰤟"
                                            return "󰤯"
                                        }
                                        color: cFg; font.pixelSize: 14; font.family: "Symbols Nerd Font"
                                    }
                                }
                            }
                            MouseArea {
                                id: hoverAvail; anchors.fill: parent
                                onClicked: {
                                    if (modelData.security === "" || modelData.security === "--") { 
                                        NetworkService.connect(modelData.ssid) 
                                    } else {
                                        var isEnterprise = modelData.security.includes("802.1X") || modelData.security.includes("EAP")
                                        wifiConnectingData = {
                                            ssid: modelData.ssid,
                                            security: modelData.security,
                                            method: isEnterprise ? "enterprise" : "wpa"
                                        }
                                        if (isEnterprise) identityInput.forceActiveFocus()
                                        else passInput.forceActiveFocus()
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1, 1, 1, 0.05) }

                // 4. Footer Block
                ColumnLayout {
                    Layout.fillWidth: true; Layout.margins: 12; spacing: 8
                    
                    RowLayout {
                        Layout.fillWidth: true; height: 32
                        Text { text: "Enable Networking"; color: cFg; font.pixelSize: 12; Layout.fillWidth: true }
                        Switch {
                            checked: NetworkService.networkingEnabled
                            onClicked: NetworkService.toggleNetworking()
                            scale: 0.8
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true; height: 32
                        Text { text: "Enable Wi-Fi"; color: cFg; font.pixelSize: 12; Layout.fillWidth: true }
                        Switch {
                            checked: NetworkService.wifiEnabled
                            onClicked: NetworkService.toggleWifi()
                            scale: 0.8
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true; height: 32; radius: 8; color: hoverEdit.hovered ? cSurface : "transparent"
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 8; spacing: 10
                            Text { text: "󰒓"; color: cAccent; font.pixelSize: 14; font.family: "Symbols Nerd Font" }
                            Text { text: "Edit Connections"; color: cFg; font.pixelSize: 12 }
                        }
                        MouseArea { id: hoverEdit; anchors.fill: parent; onClicked: NetworkService.openEditor() }
                    }
                }
            }
            
            // Password / Identity Overlay
            Rectangle {
                anchors.bottom: parent.bottom; anchors.bottomMargin: 10; anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 24; height: wifiConnectingData !== null ? (wifiConnectingData.method === "enterprise" ? 100 : 50) : 0
                color: cSurface; radius: 12; visible: height > 0; clip: true; z: 100
                border.color: cAccent; border.width: 1
                
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 10; spacing: 8
                    
                    // Identity field for Enterprise
                    TextField {
                        id: identityInput; Layout.fillWidth: true; Layout.preferredHeight: 30
                        visible: wifiConnectingData !== null && wifiConnectingData.method === "enterprise"
                        placeholderText: "Identity (Username)..."; color: cFg; font.pixelSize: 12; background: null
                    }

                    RowLayout {
                        Layout.fillWidth: true; spacing: 10
                        TextField {
                            id: passInput; Layout.fillWidth: true; Layout.preferredHeight: 30
                            placeholderText: wifiConnectingData !== null ? ("Password for " + wifiConnectingData.ssid + "...") : "Password..."
                            color: cFg; echoMode: TextField.Password; font.pixelSize: 12; background: null
                            onAccepted: connectBtn.clicked()
                        }
                        Button {
                            id: connectBtn; text: "Connect"; Layout.preferredWidth: 70; Layout.preferredHeight: 28
                            onClicked: {
                                if (wifiConnectingData.method === "enterprise") {
                                    NetworkService.connectEnterprise(wifiConnectingData.ssid, identityInput.text, passInput.text)
                                } else {
                                    NetworkService.connectWithPassword(wifiConnectingData.ssid, passInput.text)
                                }
                                wifiConnectingData = null; passInput.text = ""; identityInput.text = ""; wifiMenuOpen = false
                            }
                            background: Rectangle { color: cAccent; radius: 6 }
                            contentItem: Text { text: parent.text; color: cBg; font.bold: true; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        }
                    }
                }
            }
        }

        // --- Power Profile Menu ---
        Rectangle {
            id: powerMenu
            anchors.top: parent.top; anchors.topMargin: 60
            anchors.right: parent.right; anchors.rightMargin: 15
            width: 280; height: powerMenuOpen ? powerMenuHeight : 0
            color: Qt.rgba(0.12, 0.12, 0.18, 0.95)
            radius: 20; border.color: Qt.rgba(1, 1, 1, 0.1); border.width: 1
            visible: opacity > 0; opacity: powerMenuOpen ? 1 : 0
            
            Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
            Behavior on anchors.topMargin { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
            Behavior on opacity { NumberAnimation { duration: 300 } }

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 20; spacing: 15
                Text { text: "Power Profiles"; color: cFg; font.bold: true; font.pixelSize: 16; Layout.fillWidth: true }
                ListView {
                    id: powerList; Layout.fillWidth: true; Layout.fillHeight: true; clip: true; model: PowerProfileService.profiles; spacing: 10
                    delegate: Rectangle {
                        width: powerList.width; height: 46; radius: 14
                        readonly property color profileColor: {
                            if (modelData === "performance") return cRed
                            if (modelData === "power-saver") return cGreen
                            return cAccent
                        }
                        color: (PowerProfileService.activeProfile === modelData) ? Qt.rgba(profileColor.r, profileColor.g, profileColor.b, 0.15) : (hoverHandlerPower.hovered ? cSurface : "transparent")
                        border.color: (PowerProfileService.activeProfile === modelData) ? Qt.rgba(profileColor.r, profileColor.g, profileColor.b, 0.4) : "transparent"
                        border.width: 1
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 12; spacing: 15
                            Text {
                                text: { if (modelData === "performance") return "󰓅"; if (modelData === "power-saver") return "󰾆"; return "󰾅" }
                                color: (PowerProfileService.activeProfile === modelData) ? profileColor : cFg; font.pixelSize: 22; font.family: "Symbols Nerd Font"
                            }
                            Text { text: modelData.charAt(0).toUpperCase() + modelData.slice(1); color: (PowerProfileService.activeProfile === modelData) ? profileColor : cFg; font.bold: PowerProfileService.activeProfile === modelData; font.pixelSize: 14; Layout.fillWidth: true }
                            Text { visible: PowerProfileService.activeProfile === modelData; text: "󰄬"; color: profileColor; font.pixelSize: 16; font.family: "Symbols Nerd Font" }
                        }
                        MouseArea { anchors.fill: parent; onClicked: { PowerProfileService.setProfile(modelData); powerMenuOpen = false } }
                        HoverHandler { id: hoverHandlerPower }
                    }
                }
            }
        }
    }
}