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
    property bool bluetoothMenuOpen: false
    property bool powerMenuOpen: false

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
        var nets = (typeof NetworkService !== "undefined" && NetworkService.networks) ? NetworkService.networks : []
        var activeNets = nets.filter(function(n) { return n.active || n.ssid === NetworkService.activeWifiSsid })
        if (activeNets.length > 0) h += 80
        // Available Networks Section
        var availNets = nets.filter(function(n) { return !n.active && n.ssid !== NetworkService.activeWifiSsid })
        h += Math.min(availNets.length * rowHeight + 40, 350)
        // Footer (Networking, WiFi toggles, manual, editor)
        h += 175
        return h + 40
    }

    property real bluetoothMenuHeight: {
        var h = 60 // Header
        var devices = (typeof BluetoothService !== "undefined" && BluetoothService.devices) ? BluetoothService.devices : []
        h += Math.min(devices.length * rowHeight + 40, 350)
        h += 100 // Footer
        return h + 40
    }

    property real powerMenuHeight: 280

    implicitHeight: (wifiMenuOpen || bluetoothMenuOpen || powerMenuOpen) ? 850 : (hoverHandler.hovered ? 42 : 1)
    exclusiveZone: (wifiMenuOpen || bluetoothMenuOpen || powerMenuOpen || hoverHandler.hovered) ? 42 : 0

    Behavior on implicitHeight { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
    color: "transparent"

    HoverHandler {
        id: globalHover
        onHoveredChanged: {
            if (!hovered) {
                wifiMenuOpen = false
                bluetoothMenuOpen = false
                powerMenuOpen = false
            }
        }
    }

    // --- Dynamic Colors from Common ThemeService (Safe Access) ---
    readonly property color cBg: (typeof ThemeService !== "undefined" && ThemeService.backgroundDark) ? ThemeService.backgroundDark : "#13121c"
    readonly property color cFg: (typeof ThemeService !== "undefined" && ThemeService.text) ? ThemeService.text : "#e5e0ef"
    readonly property color cAccent: (typeof ThemeService !== "undefined" && ThemeService.accent) ? ThemeService.accent : "#8aceff"
    readonly property color cSurface: (typeof ThemeService !== "undefined" && ThemeService.surface_variant) ? ThemeService.surface_variant : "#201e29"
    readonly property color cRed: (typeof ThemeService !== "undefined" && ThemeService.error) ? ThemeService.error : "#ffb4ab"
    readonly property color cGreen: (typeof ThemeService !== "undefined" && ThemeService.success) ? ThemeService.success : "#a6e3a1"
    readonly property color cDim: (typeof ThemeService !== "undefined" && ThemeService.text_dim) ? ThemeService.text_dim : Qt.rgba(0.8, 0.8, 0.9, 0.4)

    Item {
        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
        height: 42
        HoverHandler { id: hoverHandler }
    }

    Rectangle {
        id: barContainer
        anchors.fill: parent
        anchors.topMargin: (hoverHandler.hovered || wifiMenuOpen || bluetoothMenuOpen || powerMenuOpen) ? 0 : -42
        color: "transparent"
        Behavior on anchors.topMargin { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

        // --- DYNAMIC CENTER MODULE ---
        Rectangle {
            id: centerModule
            height: 32
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top; anchors.topMargin: 5
            radius: 16; color: cBg; border.color: cSurface; border.width: 1
            z: 10
            
            implicitWidth: Math.max(50, centerLayout.implicitWidth + 24)
            Behavior on implicitWidth { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

            RowLayout {
                id: centerLayout
                anchors.centerIn: parent
                anchors.leftMargin: 12; anchors.rightMargin: 12
                spacing: 10

                // Icon / Prefix
                Text {
                    text: {
                        if (ContextService.activeClass === "foot") return ""
                        if (ContextService.activeClass === "VSCodium" || ContextService.activeClass === "Cursor") return "󰨞"
                        if (ContextService.activeClass.includes("vivaldi") || ContextService.activeClass.includes("firefox")) return "󰈹"
                        return "󰕮"
                    }
                    color: cAccent; font.pixelSize: 18; font.family: "Symbols Nerd Font"
                }

                // Dynamic Text
                Text {
                    visible: text !== ""
                    text: {
                        if (ContextService.activeClass === "foot") return ContextService.cwd
                        if (ContextService.activeClass === "VSCodium" || ContextService.activeClass === "Cursor") return ContextService.gitBranch || "Coding"
                        if (ContextService.activeClass.includes("vivaldi") || ContextService.activeClass.includes("firefox")) return ContextService.activeTitle.substring(0, 30) + (ContextService.activeTitle.length > 30 ? "..." : "")
                        return ""
                    }
                    color: cFg; font.pixelSize: 12; font.bold: true; elide: Text.ElideRight; Layout.maximumWidth: 300
                }
            }

            MouseArea { 
                anchors.fill: parent
                onClicked: {
                    if (ContextService.activeClass !== "") {
                        // Focus the window (using address if possible, but class is a safe fallback for simple setups)
                        // Actually, just calling focuswindow on the current class is the cleanest way via shell
                        Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", ContextService.activeClass])
                    } else {
                        Quickshell.execDetached(["quickshell", "-c", "dashboard"])
                    }
                }
            }
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
                    Text { text: "󰣇"; color: cAccent; font.pixelSize: 18; font.family: "Symbols Nerd Font"; MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["qs", "-c", "launcher"])
                    } }
                    RowLayout {
                        spacing: 8
                        Text { text: ""; color: cAccent; font.pixelSize: 14 }
                        Text { text: Qt.formatTime(new Date(), "HH:mm"); color: cFg; font.bold: true; font.pixelSize: 13 }
                    }
                    RowLayout {
                        id: wsRow; spacing: 6
                        Repeater {
                            model: (typeof WorkspaceService !== "undefined" && WorkspaceService.workspaces) ? WorkspaceService.workspaces : []
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
                                visible: modelData.identity !== "nm-applet" && modelData.identity !== "blueman"
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

                    Text { text: "󰅍"; color: cAccent; font.pixelSize: 14; font.family: "Symbols Nerd Font"; MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["qs", "-c", "clipboard"])
                    } }
                    Text { text: "󰞅"; color: cAccent; font.pixelSize: 14; font.family: "Symbols Nerd Font"; MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["qs", "-c", "emoji-picker"])
                    } }

                    Text { text: "󰗡"; color: cAccent; font.pixelSize: 14; font.family: "Symbols Nerd Font"; MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["qs", "-c", "todo"])
                    } }

                    Rectangle {
                        width: 26; height: 26; radius: 13
                        color: wifiMenuOpen ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.15) : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: (typeof QuickSettingsService !== "undefined" && QuickSettingsService.wifiEnabled) ? "" : "󰖪"
                            color: (typeof QuickSettingsService !== "undefined" && QuickSettingsService.wifiEnabled) ? (wifiMenuOpen ? cAccent : cFg) : cRed
                            font.pixelSize: 14; font.family: "Symbols Nerd Font"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: { wifiMenuOpen = !wifiMenuOpen; if (wifiMenuOpen) { powerMenuOpen = false; bluetoothMenuOpen = false; if (typeof NetworkService !== "undefined") NetworkService.scan() } }
                        }
                    }

                    Rectangle {
                        width: 26; height: 26; radius: 13
                        color: bluetoothMenuOpen ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.15) : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: (typeof BluetoothService !== "undefined" && BluetoothService.powered) ? "󰂯" : "󰂲"
                            color: (typeof BluetoothService !== "undefined" && BluetoothService.powered) ? (bluetoothMenuOpen ? cAccent : cFg) : cRed
                            font.pixelSize: 16; font.family: "Symbols Nerd Font"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: { bluetoothMenuOpen = !bluetoothMenuOpen; if (bluetoothMenuOpen) { powerMenuOpen = false; wifiMenuOpen = false; if (typeof BluetoothService !== "undefined") BluetoothService.scan() } }
                        }
                    }

                    RowLayout {
                        spacing: 6
                        Text { text: " " + Math.round(typeof ResourceService !== "undefined" ? ResourceService.cpu : 0) + "%"; color: cFg; font.pixelSize: 9; font.bold: true }
                        Text { text: " " + Math.round(typeof ResourceService !== "undefined" ? ResourceService.ram : 0) + "%"; color: cFg; font.pixelSize: 9; font.bold: true }
                    }

                    RowLayout {
                        spacing: 4
                        Text {
                            text: (typeof QuickSettingsService !== "undefined" && QuickSettingsService.isCharging) ? "" : ""
                            color: (typeof QuickSettingsService !== "undefined" && QuickSettingsService.isCharging) ? cGreen : cAccent; font.pixelSize: 14
                        }
                        Text { text: (typeof QuickSettingsService !== "undefined" ? QuickSettingsService.batteryLevel : 0) + "%"; color: cFg; font.bold: true; font.pixelSize: 10 }
                    }

                    Rectangle {
                        id: powerProfileBtn
                        width: 26; height: 26; radius: 13
                        readonly property color activeColor: {
                            if (typeof PowerProfileService === "undefined") return cAccent
                            return PowerProfileService.activeProfile === "performance" ? cRed :
                                   PowerProfileService.activeProfile === "power-saver" ? cGreen : cAccent
                        }

                        color: powerMenuOpen ? Qt.rgba(powerProfileBtn.activeColor.r, powerProfileBtn.activeColor.g, powerProfileBtn.activeColor.b, 0.15) : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: {
                                if (typeof PowerProfileService === "undefined") return "󰾅"
                                if (PowerProfileService.activeProfile === "performance") return "󰓅"
                                if (PowerProfileService.activeProfile === "power-saver") return "󰾆"
                                return "󰾅"
                            }
                            color: {
                                if (typeof PowerProfileService === "undefined") return cFg
                                powerMenuOpen ? powerProfileBtn.activeColor : (PowerProfileService.activeProfile !== "balanced" ? powerProfileBtn.activeColor : cFg)
                            }
                            font.pixelSize: 16; font.family: "Symbols Nerd Font"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: { powerMenuOpen = !powerMenuOpen; if (powerMenuOpen) { wifiMenuOpen = false; bluetoothMenuOpen = false } }
                        }
                    }

                    // Settings Button (Replaced Power Button)
                    Rectangle {
                        width: 24; height: 24; radius: 12; color: cSurface
                        Text { anchors.centerIn: parent; text: "󰒓"; color: cAccent; font.pixelSize: 12; font.family: "Symbols Nerd Font" }
                        MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["qs", "-c", "settings"]) }
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
            color: Qt.rgba(cBg.r, cBg.g, cBg.b, 0.98)
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
                        Text { text: "󰈀"; color: (typeof NetworkService !== "undefined" && NetworkService.ethernetStatus === "Connected") ? cGreen : cDim; font.pixelSize: 16; font.family: "Symbols Nerd Font" }
                        Text { text: "Ethernet"; color: cFg; font.pixelSize: 13; Layout.fillWidth: true }
                        Text { text: (typeof NetworkService !== "undefined" ? NetworkService.ethernetStatus : "Unknown"); color: (typeof NetworkService !== "undefined" && NetworkService.ethernetStatus === "Connected") ? cGreen : cDim; font.pixelSize: 11; font.bold: true }
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
                        Item {
                            Layout.preferredWidth: scanRow.implicitWidth
                            Layout.preferredHeight: 30
                            RowLayout {
                                id: scanRow
                                anchors.fill: parent
                                spacing: 6
                                Text {
                                    id: scanIcon
                                    text: "󰑐"
                                    color: cAccent
                                    font.pixelSize: 12
                                    font.family: "Symbols Nerd Font"
                                    transformOrigin: Item.Center
                                    RotationAnimation on rotation {
                                        running: typeof NetworkService !== "undefined" && NetworkService.scanning
                                        from: 0; to: 360; duration: 1000; loops: Animation.Infinite
                                    }
                                }
                                Text {
                                    text: (typeof NetworkService !== "undefined" && NetworkService.scanning) ? "Scanning..." : "Scan"
                                    color: cAccent
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: if (typeof NetworkService !== "undefined") NetworkService.scan()
                            }
                        }
                    }

                    // Show currently connected network
                    Repeater {
                        model: (typeof NetworkService !== "undefined" && NetworkService.networks) ? NetworkService.networks.filter(function(n) { return n.active || n.ssid === NetworkService.activeWifiSsid }) : []
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
                        model: (typeof NetworkService !== "undefined" && NetworkService.networks) ? NetworkService.networks.filter(function(n) { return !n.active && n.ssid !== NetworkService.activeWifiSsid }) : []

                        Text {
                            anchors.centerIn: parent; text: "No networks found"; color: cDim; font.pixelSize: 12
                            visible: wifiList.count === 0 && (typeof NetworkService !== "undefined" && !NetworkService.scanning)
                        }
                        Text {
                            anchors.centerIn: parent; text: "Scanning..."; color: cAccent; font.pixelSize: 12
                            visible: wifiList.count === 0 && (typeof NetworkService !== "undefined" && NetworkService.scanning)
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
                                    var isEnterprise = modelData.security.includes("802.1X") || modelData.security.includes("EAP")
                                    var isOpen = modelData.security === "" || modelData.security === "--"
                                    var method = isEnterprise ? "enterprise" : (isOpen ? "open" : "wpa")

                                    Quickshell.execDetached([
                                        "sh", "-c",
                                        "QS_WIFI_SSID='" + modelData.ssid.replace(/'/g, "'\\''") + "' " +
                                        "QS_WIFI_SECURITY='" + modelData.security + "' " +
                                        "QS_WIFI_METHOD='" + method + "' " +
                                        "QS_WIFI_SIGNAL='" + modelData.signal + "' " +
                                        "quickshell -c /home/zoro/.config/quickshell/network-dialog"
                                    ])
                                    wifiMenuOpen = false
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
                            checked: typeof NetworkService !== "undefined" && NetworkService.networkingEnabled
                            onClicked: if (typeof NetworkService !== "undefined") NetworkService.toggleNetworking()
                            scale: 0.8
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true; height: 32
                        Text { text: "Enable Wi-Fi"; color: cFg; font.pixelSize: 12; Layout.fillWidth: true }
                        Switch {
                            checked: typeof NetworkService !== "undefined" && NetworkService.wifiEnabled
                            onClicked: if (typeof NetworkService !== "undefined") NetworkService.toggleWifi()
                            scale: 0.8
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true; height: 32; radius: 8; color: hoverHidden.hovered ? cSurface : "transparent"
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 8; spacing: 10
                            Text { text: "󰒄"; color: cAccent; font.pixelSize: 14; font.family: "Symbols Nerd Font" }
                            Text { text: "Hidden Network / Manual"; color: cFg; font.pixelSize: 12 }
                        }
                        MouseArea {
                            id: hoverHidden; anchors.fill: parent
                            onClicked: {
                                Quickshell.execDetached([
                                    "sh", "-c",
                                    "QS_WIFI_SSID='' " +
                                    "QS_WIFI_SECURITY='WPA2' " +
                                    "QS_WIFI_METHOD='enterprise' " +
                                    "QS_WIFI_SIGNAL='100' " +
                                    "quickshell -c /home/zoro/.config/quickshell/network-dialog"
                                ])
                                wifiMenuOpen = false
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true; height: 32; radius: 8; color: hoverEdit.hovered ? cSurface : "transparent"
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 8; spacing: 10
                            Text { text: "󰒓"; color: cAccent; font.pixelSize: 14; font.family: "Symbols Nerd Font" }
                            Text { text: "Edit Connections"; color: cFg; font.pixelSize: 12 }
                        }
                        MouseArea { id: hoverEdit; anchors.fill: parent; onClicked: if (typeof NetworkService !== "undefined") NetworkService.openEditor() }
                    }
                }
            }
        }

        // --- Bluetooth Island ---
        Rectangle {
            id: bluetoothIsland
            anchors.top: parent.top; anchors.topMargin: bluetoothMenuOpen ? 52 : 40
            anchors.right: parent.right; anchors.rightMargin: 15
            width: menuWidth; height: bluetoothMenuOpen ? bluetoothMenuHeight : 0
            color: Qt.rgba(cBg.r, cBg.g, cBg.b, 0.98)
            radius: 20; border.color: Qt.rgba(1, 1, 1, 0.1); border.width: 1
            visible: opacity > 0; opacity: bluetoothMenuOpen ? 1 : 0

            Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
            Behavior on anchors.topMargin { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
            Behavior on opacity { NumberAnimation { duration: 300 } }

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 0; spacing: 0

                // Header
                ColumnLayout {
                    Layout.fillWidth: true; Layout.margins: 12; spacing: 8
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "BLUETOOTH DEVICES"; color: cDim; font.bold: true; font.pixelSize: 10; Layout.fillWidth: true }

                        // Scan Button
                        Item {
                            Layout.preferredWidth: btScanRow.implicitWidth
                            Layout.preferredHeight: 30
                            RowLayout {
                                id: btScanRow
                                anchors.fill: parent
                                spacing: 6
                                Text {
                                    text: "󰑐"
                                    color: cAccent
                                    font.pixelSize: 12
                                    font.family: "Symbols Nerd Font"
                                    transformOrigin: Item.Center
                                    RotationAnimation on rotation {
                                        running: typeof BluetoothService !== "undefined" && BluetoothService.scanning
                                        from: 0; to: 360; duration: 1000; loops: Animation.Infinite
                                    }
                                }
                                Text {
                                    text: (typeof BluetoothService !== "undefined" && BluetoothService.scanning) ? "Scanning..." : "Scan"
                                    color: cAccent
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: if (typeof BluetoothService !== "undefined") BluetoothService.scan()
                            }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1, 1, 1, 0.05) }

                // Device List
                ColumnLayout {
                    Layout.fillWidth: true; Layout.leftMargin: 12; Layout.rightMargin: 12; Layout.bottomMargin: 12; spacing: 8

                    ListView {
                        id: btList; Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 4
                        model: (typeof BluetoothService !== "undefined" && BluetoothService.devices) ? BluetoothService.devices : []

                        Text {
                            anchors.centerIn: parent; text: "No devices found"; color: cDim; font.pixelSize: 12
                            visible: btList.count === 0 && (typeof BluetoothService !== "undefined" && !BluetoothService.scanning)
                        }
                        Text {
                            anchors.centerIn: parent; text: "Scanning..."; color: cAccent; font.pixelSize: 12
                            visible: btList.count === 0 && (typeof BluetoothService !== "undefined" && BluetoothService.scanning)
                        }

                        delegate: Rectangle {
                            width: btList.width; height: rowHeight; radius: 8
                            color: hoverBt.hovered ? cSurface : "transparent"
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 12; spacing: 12
                                Text { text: modelData.icon; color: modelData.connected ? cGreen : cAccent; font.pixelSize: 16; font.family: "Symbols Nerd Font" }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 2
                                    Text { text: modelData.name; color: modelData.connected ? cGreen : cFg; font.pixelSize: 12; elide: Text.ElideRight; font.bold: modelData.connected }
                                    Text { text: modelData.connected ? "Connected" : modelData.mac; color: modelData.connected ? cGreen : cDim; font.pixelSize: 9 }
                                }
                            }
                            MouseArea {
                                id: hoverBt; anchors.fill: parent
                                onClicked: {
                                    if (typeof BluetoothService !== "undefined") {
                                        if (modelData.connected) BluetoothService.disconnect(modelData.mac)
                                        else BluetoothService.connect(modelData.mac)
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1, 1, 1, 0.05) }

                // Footer
                ColumnLayout {
                    Layout.fillWidth: true; Layout.margins: 12; spacing: 8

                    RowLayout {
                        Layout.fillWidth: true; height: 32
                        Text { text: "Enable Bluetooth"; color: cFg; font.pixelSize: 12; Layout.fillWidth: true }
                        Switch {
                            checked: typeof BluetoothService !== "undefined" && BluetoothService.powered
                            onClicked: if (typeof BluetoothService !== "undefined") BluetoothService.togglePower()
                            scale: 0.8
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true; height: 32; radius: 8; color: hoverBtMan.hovered ? cSurface : "transparent"
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 8; spacing: 10
                            Text { text: "󰒓"; color: cAccent; font.pixelSize: 14; font.family: "Symbols Nerd Font" }
                            Text { text: "Bluetooth Manager"; color: cFg; font.pixelSize: 12 }
                        }
                        MouseArea { id: hoverBtMan; anchors.fill: parent; onClicked: if (typeof BluetoothService !== "undefined") BluetoothService.openManager() }
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
            color: Qt.rgba(cBg.r, cBg.g, cBg.b, 0.95)
            radius: 20; border.color: Qt.rgba(1, 1, 1, 0.1); border.width: 1
            visible: opacity > 0; opacity: powerMenuOpen ? 1 : 0

            Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
            Behavior on anchors.topMargin { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
            Behavior on opacity { NumberAnimation { duration: 300 } }

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 20; spacing: 15
                Text { text: "Power Profiles"; color: cFg; font.bold: true; font.pixelSize: 16; Layout.fillWidth: true }
                ListView {
                    id: powerList; Layout.fillWidth: true; Layout.fillHeight: true; clip: true; model: (typeof PowerProfileService !== "undefined" && PowerProfileService.profiles) ? PowerProfileService.profiles : []; spacing: 10
                    delegate: Rectangle {
                        width: powerList.width; height: 46; radius: 14
                        readonly property color profileColor: {
                            if (typeof PowerProfileService === "undefined") return cAccent
                            if (modelData === "performance") return cRed
                            if (modelData === "power-saver") return cGreen
                            return cAccent
                        }
                        color: (typeof PowerProfileService !== "undefined" && PowerProfileService.activeProfile === modelData) ? Qt.rgba(profileColor.r, profileColor.g, profileColor.b, 0.15) : (hoverHandlerPower.hovered ? cSurface : "transparent")
                        border.color: (typeof PowerProfileService !== "undefined" && PowerProfileService.activeProfile === modelData) ? Qt.rgba(profileColor.r, profileColor.g, profileColor.b, 0.4) : "transparent"
                        border.width: 1
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 12; spacing: 15
                            Text {
                                text: { if (modelData === "performance") return "󰓅"; if (modelData === "power-saver") return "󰾆"; return "󰾅" }
                                color: (typeof PowerProfileService !== "undefined" && PowerProfileService.activeProfile === modelData) ? profileColor : cFg; font.pixelSize: 22; font.family: "Symbols Nerd Font"
                            }
                            Text { text: modelData.charAt(0).toUpperCase() + modelData.slice(1); color: (typeof PowerProfileService !== "undefined" && PowerProfileService.activeProfile === modelData) ? profileColor : cFg; font.bold: (typeof PowerProfileService !== "undefined" && PowerProfileService.activeProfile === modelData); font.pixelSize: 14; Layout.fillWidth: true }
                            Text { visible: (typeof PowerProfileService !== "undefined" && PowerProfileService.activeProfile === modelData); text: "󰄬"; color: profileColor; font.pixelSize: 16; font.family: "Symbols Nerd Font" }
                        }
                        MouseArea { anchors.fill: parent; onClicked: { if (typeof PowerProfileService !== "undefined") { PowerProfileService.setProfile(modelData); powerMenuOpen = false } } }
                        HoverHandler { id: hoverHandlerPower }
                    }
                }
            }
        }
    }
}