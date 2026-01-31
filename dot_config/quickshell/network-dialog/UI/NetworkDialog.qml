import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../Services"

PanelWindow {
    id: root

    property var connectionData: null // { ssid: string, security: string, method: string, signal: int }
    property string manualSsid: ""

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: connectionData !== null ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "qs-network-dialog"

    visible: connectionData !== null
    anchors.bottom: true
    anchors.top: true
    anchors.left: true
    anchors.right: true

    color: "transparent"

    // Theme Colors
    readonly property color cBg: "#11111b"
    readonly property color cSurface: "#1e1e2e"
    readonly property color cSurfaceVariant: "#313244"
    readonly property color cAccent: "#cba6f7"
    readonly property color cText: "#cdd6f4"
    readonly property color cDim: "#6c7086"
    readonly property color cRed: "#f38ba8"
    readonly property color cGreen: "#a6e3a1"
    readonly property color cBlue: "#89b4fa"

    // State
    property bool showPassword: false
    property bool autoConnect: true
    property string metered: "automatic"
    property string ipMethod: "dhcp"
    property string proxyMethod: "none"
    
    property string eapMethod: "PEAP"
    property string phase2: "MSCHAPV2"
    property string caCertPath: ""
    property string staticIp: ""
    property string gateway: ""
    property string dns: ""
    property string proxyUrl: ""
    property string proxyPac: ""

    function close() {
        connectionData = null
        Qt.quit()
    }

    readonly property string targetSsid: (connectionData && connectionData.ssid !== "") ? connectionData.ssid : manualSsid

    readonly property bool canConnect: {
        if (!connectionData) return false
        if (targetSsid.length === 0) return false
        if (connectionData.method === "open") return true
        if (connectionData.method === "enterprise") {
            if (identityInput.input_text.length === 0) return false
            if (eapMethod !== "TLS" && passInput.text.length === 0) return false
        }
        if (connectionData.method === "wpa" && passInput.text.length < 8) return false
        if (ipMethod === "static" && staticIp.length === 0) return false
        return true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: close()
        Rectangle { anchors.fill: parent; color: "#000000"; opacity: root.connectionData !== null ? 0.7 : 0; Behavior on opacity { NumberAnimation { duration: 300 } } }
    }

    Rectangle {
        id: dialog
        anchors.centerIn: parent
        width: 540; height: Math.min(Screen.height * 0.85, 750)
        color: cBg; radius: 32; border.color: Qt.rgba(1, 1, 1, 0.1); border.width: 1; clip: true
        
        scale: visible ? 1 : 0.9; opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 250 } }
        Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

        ColumnLayout {
            anchors.fill: parent; spacing: 0

            // Fixed Header
            Rectangle {
                Layout.fillWidth: true; height: 100; color: "transparent"
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 45; anchors.rightMargin: 45; spacing: 15
                    ColumnLayout {
                        spacing: 4; Layout.fillWidth: true
                        Text { text: "ADVANCED NETWORK SETUP"; color: cAccent; font.bold: true; font.pixelSize: 10; font.letterSpacing: 2 }
                        Text { text: targetSsid !== "" ? targetSsid : "Enter SSID"; color: cText; font.bold: true; font.pixelSize: 24; elide: Text.ElideRight }
                    }
                    Text {
                        text: {
                            if (!root.connectionData || root.connectionData.ssid === "") return "󰤨"
                            var s = root.connectionData.signal
                            if (s >= 80) return "󰤨"; if (s >= 60) return "󰤥"; if (s >= 40) return "󰤢"; if (s >= 20) return "󰤟"; return "󰤯"
                        }
                        color: cAccent; font.pixelSize: 32; font.family: "Symbols Nerd Font"
                    }
                }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width - 90; height: 1; color: Qt.rgba(1, 1, 1, 0.05); anchors.horizontalCenter: parent.horizontalCenter }
            }

            // Scrollable Body
            Flickable {
                id: flickable
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                contentHeight: contentColumn.height + 60
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; active: true }

                Column {
                    id: contentColumn
                    x: 45; y: 30
                    width: parent.width - 90
                    spacing: 35

                    // 0. Manual SSID Entry
                    ColumnLayout {
                        width: parent.width; spacing: 12
                        visible: root.connectionData && root.connectionData.ssid === ""
                        Text { text: "NETWORK NAME"; color: cAccent; font.bold: true; font.pixelSize: 11; font.letterSpacing: 1.5 }
                        InputField { 
                            placeholder: "Enter Wi-Fi Name (SSID)..."
                            icon: "󰖩"
                            onOnInputChanged: (t) => root.manualSsid = t
                        }
                    }

                    // 1. Security
                    ColumnLayout {
                        width: parent.width; spacing: 15
                        Text { text: "SECURITY"; color: cAccent; font.bold: true; font.pixelSize: 11; font.letterSpacing: 1.5 }
                        RowLayout {
                            Layout.fillWidth: true; spacing: 10
                            Repeater {
                                model: [
                                    { name: "WPA/WPA2", method: "wpa" },
                                    { name: "Enterprise", method: "enterprise" },
                                    { name: "None", method: "open" }
                                ]
                                delegate: TabButton {
                                    active: root.connectionData && root.connectionData.method === modelData.method
                                    text: modelData.name; onClicked: { var d = root.connectionData; d.method = modelData.method; root.connectionData = null; root.connectionData = d }
                                }
                            }
                        }
                    }

                    // 2. Security Details
                    ColumnLayout {
                        width: parent.width; spacing: 25; visible: root.connectionData && root.connectionData.method !== "open"

                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 15; visible: root.connectionData && root.connectionData.method === "enterprise"
                            
                            RowLayout {
                                Layout.fillWidth: true; spacing: 15
                                InputField { label: "EAP METHOD"; Layout.fillWidth: true; value: root.eapMethod; options: ["PEAP", "TLS", "TTLS", "PWD"]; onOptionSelected: (opt) => root.eapMethod = opt }
                                InputField { label: "PHASE 2 AUTH"; Layout.fillWidth: true; value: root.phase2; options: ["MSCHAPV2", "GTC", "MD5"]; onOptionSelected: (opt) => root.phase2 = opt; visible: root.eapMethod !== "TLS" }
                            }

                            InputField { 
                                label: "CA CERTIFICATE"
                                placeholder: "Ignore verification (None)"
                                onOnInputChanged: (t) => root.caCertPath = t
                                icon: "󰈙"
                                MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["zenity", "--file-selection", "--title='Select CA Certificate'"], (out) => root.caCertPath = out.trim()) }
                            }

                            InputField { label: "IDENTITY"; id: identityInput; placeholder: "Username / ID (e.g. 23BAI...)" }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 8
                            Text { text: "PASSWORD / PRIVATE KEY"; color: cDim; font.bold: true; font.pixelSize: 10 }
                            RowLayout {
                                Layout.fillWidth: true; spacing: 10
                                TextField {
                                    id: passInput; Layout.fillWidth: true; Layout.preferredHeight: 48
                                    placeholderText: "Enter password..."; color: cText; font.pixelSize: 14; echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
                                    background: Rectangle { color: cSurface; radius: 14; border.color: passInput.activeFocus ? cAccent : "transparent"; border.width: 1.5 }
                                }
                                IconButton { icon: root.showPassword ? "󰈈" : "󰈉"; active: root.showPassword; onClicked: root.showPassword = !root.showPassword }
                            }
                        }
                    }

                    // 3. IP Settings
                    ColumnLayout {
                        width: parent.width; spacing: 15
                        Text { text: "IP CONFIGURATION"; color: cAccent; font.bold: true; font.pixelSize: 11; font.letterSpacing: 1.5 }
                        RowLayout {
                            Layout.fillWidth: true; spacing: 10
                            TabButton { text: "DHCP (Automatic)"; active: root.ipMethod === "dhcp"; onClicked: root.ipMethod = "dhcp" }
                            TabButton { text: "Static (Manual)"; active: root.ipMethod === "static"; onClicked: root.ipMethod = "static" }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 15; visible: root.ipMethod === "static"
                            InputField { label: "IP ADDRESS / PREFIX"; placeholder: "e.g. 192.168.1.100/24"; onOnInputChanged: (t) => root.staticIp = t }
                            RowLayout {
                                Layout.fillWidth: true; spacing: 15
                                InputField { label: "GATEWAY"; placeholder: "192.168.1.1"; onOnInputChanged: (t) => root.gateway = t }
                                InputField { label: "DNS"; placeholder: "8.8.8.8"; onOnInputChanged: (t) => root.dns = t }
                            }
                        }
                    }

                    // 4. Advanced Options
                    ColumnLayout {
                        width: parent.width; spacing: 15
                        Text { text: "NETWORK OPTIONS"; color: cAccent; font.bold: true; font.pixelSize: 11; font.letterSpacing: 1.5 }
                        RowLayout {
                            Layout.fillWidth: true; spacing: 20
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 10
                                Text { text: "METERED CONNECTION"; color: cDim; font.bold: true; font.pixelSize: 9 }
                                RowLayout {
                                    Layout.fillWidth: true; spacing: 5
                                    TabButton { text: "Auto"; active: root.metered === "automatic"; onClicked: root.metered = "automatic"; height: 36 }
                                    TabButton { text: "Yes"; active: root.metered === "yes"; onClicked: root.metered = "yes"; height: 36 }
                                    TabButton { text: "No"; active: root.metered === "no"; onClicked: root.metered = "no"; height: 36 }
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 10
                                Text { text: "AUTO-CONNECT"; color: cDim; font.bold: true; font.pixelSize: 9 }
                                TabButton { text: root.autoConnect ? "Enabled" : "Disabled"; active: root.autoConnect; onClicked: root.autoConnect = !root.autoConnect; height: 36; Layout.fillWidth: true }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 10; Layout.topMargin: 10
                            Text { text: "PROXY SETTINGS"; color: cDim; font.bold: true; font.pixelSize: 9 }
                            RowLayout {
                                Layout.fillWidth: true; spacing: 5
                                TabButton { text: "None"; active: root.proxyMethod === "none"; onClicked: root.proxyMethod = "none"; height: 36 }
                                TabButton { text: "Auto"; active: root.proxyMethod === "auto"; onClicked: root.proxyMethod = "auto"; height: 36 }
                                TabButton { text: "Manual"; active: root.proxyMethod === "manual"; onClicked: root.proxyMethod = "manual"; height: 36 }
                            }
                            InputField { visible: root.proxyMethod === "manual"; label: "HTTP PROXY"; placeholder: "http://proxy.example.com:8080"; onOnInputChanged: (t) => root.proxyUrl = t }
                            InputField { visible: root.proxyMethod === "auto"; label: "PAC URL"; placeholder: "http://example.com/proxy.pac"; onOnInputChanged: (t) => root.proxyPac = t }
                        }
                    }
                }
            }

            // Fixed Footer
            Rectangle {
                Layout.fillWidth: true; height: 110; color: "transparent"
                Rectangle { anchors.top: parent.top; width: parent.width - 90; height: 1; color: Qt.rgba(1, 1, 1, 0.05); anchors.horizontalCenter: parent.horizontalCenter }
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 45; anchors.rightMargin: 45; spacing: 15
                    Button {
                        Layout.fillWidth: true; Layout.preferredHeight: 52; text: "CANCEL"
                        onClicked: root.close()
                        background: Rectangle { color: "transparent"; radius: 16; border.color: cSurfaceVariant; border.width: 1 }
                        contentItem: Text { text: parent.text; color: cDim; font.bold: true; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    }
                    Button {
                        id: connectBtn; Layout.fillWidth: true; Layout.preferredHeight: 52; text: "CONNECT"
                        enabled: root.canConnect
                        onClicked: {
                            NetworkService.connectAdvanced({
                                ssid: root.targetSsid,
                                method: root.connectionData.method,
                                identity: identityInput.input_text,
                                password: passInput.text,
                                eapMethod: root.eapMethod,
                                phase2: root.phase2,
                                caCert: root.caCertPath,
                                autoConnect: root.autoConnect,
                                metered: root.metered,
                                ipMethod: root.ipMethod,
                                staticIp: root.staticIp,
                                gateway: root.gateway,
                                dns: root.dns,
                                proxyMethod: root.proxyMethod,
                                proxyUrl: root.proxyUrl,
                                proxyPac: root.proxyPac
                            })
                            root.close()
                        }
                        background: Rectangle { color: parent.enabled ? (parent.pressed ? Qt.darker(cAccent, 1.1) : cAccent) : cSurface; radius: 16; opacity: parent.enabled ? 1 : 0.5 }
                        contentItem: Text { text: parent.text; color: parent.enabled ? cBg : cDim; font.bold: true; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    }
                }
            }
        }
    }

    // Components
    component TabButton: Rectangle {
        property string text: ""
        property bool active: false
        signal clicked()
        Layout.fillWidth: true; height: 42; radius: 14
        color: active ? cAccent : cSurface
        Text { anchors.centerIn: parent; text: parent.text; color: active ? cBg : cText; font.bold: true; font.pixelSize: 11 }
        MouseArea { anchors.fill: parent; onClicked: parent.clicked() }
    }

    component InputField: ColumnLayout {
        property string label: ""
        property string placeholder: ""
        property string text: ""
        readonly property alias input_text: input.text
        property string icon: ""
        property var options: null
        property string value: ""
        signal onInputChanged(string t)
        signal optionSelected(string opt)
        
        Layout.fillWidth: true; spacing: 8
        Text { text: label; color: cDim; font.bold: true; font.pixelSize: 9; visible: label !== "" }
        
        Rectangle {
            Layout.fillWidth: true; height: 48; radius: 14; color: cSurface
            border.color: (input.activeFocus || optionsRow.visible) ? cAccent : "transparent"; border.width: 1.5
            
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 15; anchors.rightMargin: 15
                Text { visible: icon !== ""; text: icon; color: cAccent; font.pixelSize: 18; font.family: "Symbols Nerd Font" }
                TextInput {
                    id: input; Layout.fillWidth: true; color: cText; font.pixelSize: 14; clip: true
                    text: parent.parent.parent.text
                    onTextChanged: parent.parent.parent.onInputChanged(text)
                    visible: options === null
                }
                Text { 
                    text: parent.parent.parent.placeholder
                    color: cDim; font.pixelSize: 14
                    visible: input.visible && input.text === "" && !input.activeFocus
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: input.left
                }
                
                RowLayout {
                    id: optionsRow; Layout.fillWidth: true; visible: options !== null; spacing: 8
                    Repeater {
                        model: options
                        delegate: Rectangle {
                            height: 32; Layout.fillWidth: true; radius: 10
                            color: value === modelData ? cAccent : cSurfaceVariant
                            Text { anchors.centerIn: parent; text: modelData; color: value === modelData ? cBg : cText; font.bold: true; font.pixelSize: 10 }
                            MouseArea { anchors.fill: parent; onClicked: optionSelected(modelData) }
                        }
                    }
                }
            }
        }
    }

    component IconButton: Rectangle {
        property string icon: ""
        property bool active: false
        signal clicked()
        width: 48; height: 48; radius: 14; color: cSurface
        Text { anchors.centerIn: parent; text: icon; color: active ? cAccent : cDim; font.pixelSize: 20; font.family: "Symbols Nerd Font" }
        MouseArea { anchors.fill: parent; onClicked: parent.clicked() }
    }
}