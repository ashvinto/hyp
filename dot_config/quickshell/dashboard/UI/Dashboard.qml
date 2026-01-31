import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../Services"

PanelWindow {
    id: root
    
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: "transparent"
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "dashboard"

    property bool visible_state: false
    Component.onCompleted: visible_state = true

    function close() {
        visible_state = false
        exitTimer.start()
    }

    Timer { id: exitTimer; interval: 300; onTriggered: Qt.quit() }

    readonly property color cBg: ThemeService.background
    readonly property color cCard: ThemeService.surface
    readonly property color cSurface: ThemeService.surface_variant
    readonly property color cBorder: Qt.rgba(1, 1, 1, 0.05)
    readonly property color cText: ThemeService.text
    readonly property color cAccent: ThemeService.accent
    readonly property color cDim: ThemeService.text_dim
    readonly property color cGreen: ThemeService.success
    readonly property color cRed: ThemeService.error
    readonly property color cBlue: "#89b4fa"

    property var currentTime: new Date()
    Timer { 
        interval: 1000; running: true; repeat: true; 
        onTriggered: { root.currentTime = new Date(); if (root.visible) WorkspaceService.update() } 
    }

    // Main Container with Opacity behavior
    Rectangle {
        id: mainContainer
        anchors.fill: parent
        color: "transparent"
        opacity: visible_state ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        
        MouseArea { anchors.fill: parent; onClicked: root.close() }
        focus: true; Keys.onEscapePressed: root.close()

        MultiEffect {
            anchors.fill: parent
            source: backgroundRect
            blurEnabled: true
            blur: 0.6
        }

        Rectangle {
            id: backgroundRect
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.4)
            visible: false
        }

        // --- Main Content ---
        GridLayout {
            anchors.centerIn: parent
            columns: 3
            columnSpacing: 30
            rowSpacing: 30
            width: 1100
            
            transform: Scale {
                origin.x: 550; origin.y: 350
                xScale: visible_state ? 1 : 0.95
                yScale: visible_state ? 1 : 0.95
                Behavior on xScale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
                Behavior on yScale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
            }

            // 1. Profile Card
            DashboardCard {
                Layout.preferredWidth: 340; Layout.preferredHeight: 320
                ColumnLayout {
                    anchors.centerIn: parent; spacing: 25
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 100; height: 100; radius: 50; color: cAccent
                        layer.enabled: true
                        layer.effect: MultiEffect { shadowEnabled: true; shadowColor: cAccent; shadowOpacity: 0.3; shadowBlur: 0.5 }
                        
                        Text {
                            anchors.centerIn: parent; text: SystemService.user[0].toUpperCase()
                            font.pixelSize: 42; font.bold: true; color: cBg
                        }
                    }
                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter; spacing: 4
                        Text { text: SystemService.greeting; color: cAccent; font.bold: true; font.pixelSize: 12; font.letterSpacing: 2; Layout.alignment: Qt.AlignHCenter }
                        Text { text: SystemService.user; color: cText; font.pixelSize: 26; font.bold: true; Layout.alignment: Qt.AlignHCenter }
                    }
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter; spacing: 30
                        StatItem { label: "UPTIME"; value: SystemService.uptime }
                        Rectangle { width: 1; height: 20; color: cBorder }
                        StatItem { label: "OS AGE"; value: SystemService.osAge }
                    }
                }
            }

            // 2. Clock Card
            DashboardCard {
                Layout.preferredWidth: 340; Layout.preferredHeight: 320
                ColumnLayout {
                    anchors.centerIn: parent; spacing: 5
                    Text {
                        text: Qt.formatTime(root.currentTime, "HH:mm")
                        color: cText; font.pixelSize: 84; font.bold: true; font.family: "JetBrains Mono"
                    }
                    Text {
                        text: Qt.formatDate(root.currentTime, "dddd, MMMM d")
                        color: cDim; font.pixelSize: 16; font.letterSpacing: 1; Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            // 3. Workspaces & Battery
            DashboardCard {
                Layout.preferredWidth: 340; Layout.preferredHeight: 320
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 30; spacing: 20
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Workspaces"; color: cText; font.bold: true; font.pixelSize: 16; Layout.fillWidth: true }
                        AnimatedImage { source: "../assets/bongocat.gif"; width: 40; height: 40; fillMode: Image.PreserveAspectFit; opacity: 0.8 }
                    }
                    Flow {
                        Layout.fillWidth: true; spacing: 12
                        Repeater {
                            model: WorkspaceService.workspaces
                            delegate: Rectangle {
                                width: 46; height: 46; radius: 12
                                color: modelData.id === WorkspaceService.activeId ? cAccent : cSurface
                                border.color: modelData.id === WorkspaceService.activeId ? cAccent : cBorder
                                Text { anchors.centerIn: parent; text: modelData.id; color: modelData.id === WorkspaceService.activeId ? cBg : cText; font.bold: true }
                                MouseArea { anchors.fill: parent; onClicked: WorkspaceService.goTo(modelData.id) }
                            }
                        }
                    }
                    Item { Layout.fillHeight: true }
                    
                    // Battery Section
                    Rectangle {
                        Layout.fillWidth: true; height: 70; color: cSurface; radius: 20
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 15; spacing: 15
                            Text { 
                                text: QuickSettingsService.isCharging ? "󱐋" : "󰁹"
                                color: QuickSettingsService.isCharging ? cGreen : (QuickSettingsService.batteryLevel < 20 ? cRed : cAccent)
                                font.pixelSize: 28 
                            }
                            ColumnLayout {
                                spacing: 0
                                Text { text: QuickSettingsService.isCharging ? "CHARGING" : "BATTERY"; color: cDim; font.bold: true; font.pixelSize: 9 }
                                Text { text: QuickSettingsService.batteryLevel + "%"; color: cText; font.bold: true; font.pixelSize: 18 }
                            }
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                width: 60; height: 24; radius: 12; color: Qt.rgba(1, 1, 1, 0.05)
                                Text { 
                                    anchors.centerIn: parent; text: QuickSettingsService.isCharging ? "AC" : "DC"
                                    color: cDim; font.bold: true; font.pixelSize: 10 
                                }
                            }
                        }
                    }
                }
            }

            // 4. Media Card
            DashboardCard {
                Layout.preferredWidth: 340; Layout.preferredHeight: 340; clip: true
                FullMediaPlayer { anchors.centerIn: parent; width: parent.width - 40 }
            }

            // 5. Resources Card
            DashboardCard {
                Layout.preferredWidth: 340; Layout.preferredHeight: 340
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 30; spacing: 20
                    Text { text: "Resource Monitor"; color: cText; font.bold: true; font.pixelSize: 16 }
                    GridLayout {
                        columns: 3; columnSpacing: 15; rowSpacing: 20; Layout.fillWidth: true
                        ResourceGauge { label: "CPU"; value: ResourceService.cpu; color: cRed }
                        ResourceGauge { label: "RAM"; value: ResourceService.ram; color: "#fab387" }
                        ResourceGauge { label: "DISK"; value: parseFloat(ResourceService.disk); color: cGreen }
                        ResourceGauge { label: "GPU"; value: ResourceService.gpu; color: cBlue }
                        ResourceGauge { label: "C-TEMP"; value: ResourceService.cpuTemp; color: "#eba0ac"; suffix: "°" }
                        ResourceGauge { label: "G-TEMP"; value: ResourceService.gpuTemp; color: "#74c7ec"; suffix: "°" }
                    }
                }
            }

            // 6. System Controls
            DashboardCard {
                Layout.preferredWidth: 340; Layout.preferredHeight: 340
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 30; spacing: 25
                    Text { text: "System Actions"; color: cText; font.bold: true; font.pixelSize: 16 }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 15
                        SystemButton { icon: "󰖩"; label: "WIFI"; active: QuickSettingsService.wifiEnabled; onClicked: QuickSettingsService.toggleWifi() }
                        SystemButton { icon: "󰂯"; label: "BT"; active: QuickSettingsService.btEnabled; onClicked: QuickSettingsService.toggleBluetooth() }
                        SystemButton { icon: "󰌾"; label: "LOCK"; active: false; onClicked: QuickSettingsService.lock() }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 12
                        PowerButton { btnText: "Reboot System"; btnIcon: "󰑓"; btnColor: cSurface; onClicked: QuickSettingsService.reboot() }
                        PowerButton { btnText: "Power Off"; btnIcon: "󰐥"; btnColor: cRed; txtColor: cBg; onClicked: QuickSettingsService.shutdown() }
                    }
                }
            }
        }
    }

    // --- Internal Components ---

    component DashboardCard: Rectangle {
        color: cCard; radius: 32; border.color: cBorder; border.width: 1
        layer.enabled: true
        layer.effect: MultiEffect { shadowEnabled: true; shadowOpacity: 0.1; shadowBlur: 0.3; shadowVerticalOffset: 5 }
    }

    component StatItem: ColumnLayout {
        property string label: ""; property string value: ""
        spacing: 4; Layout.alignment: Qt.AlignHCenter
        Text { text: label; color: cDim; font.bold: true; font.pixelSize: 10; Layout.alignment: Qt.AlignHCenter }
        Text { text: value; color: cText; font.bold: true; font.pixelSize: 14; Layout.alignment: Qt.AlignHCenter }
    }

    component ResourceGauge: ColumnLayout {
        property string label: ""; property real value: 0; property color color: cAccent; property string suffix: "%"
        spacing: 10; Layout.alignment: Qt.AlignHCenter
        Item {
            width: 75; height: 75; Layout.alignment: Qt.AlignHCenter
            Shape {
                anchors.fill: parent; layer.enabled: true; layer.samples: 4
                ShapePath {
                    strokeColor: cSurface; strokeWidth: 6; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                    PathAngleArc { centerX: 37.5; centerY: 37.5; radiusX: 30; radiusY: 30; startAngle: -90; sweepAngle: 360 }
                }
                ShapePath {
                    strokeColor: parent.parent.color; strokeWidth: 6; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                    PathAngleArc { 
                        centerX: 37.5; centerY: 37.5; radiusX: 30; radiusY: 30; startAngle: -90; 
                        sweepAngle: (Math.min(value, 100) / 100) * 360 
                        Behavior on sweepAngle { NumberAnimation { duration: 1000; easing.type: Easing.OutCubic } }
                    }
                }
            }
            Text { anchors.centerIn: parent; text: Math.round(value) + suffix; color: cText; font.pixelSize: 14; font.bold: true; font.family: "JetBrains Mono" }
        }
        Text { text: label; color: cDim; font.bold: true; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }
    }

    component SystemButton: ColumnLayout {
        property string icon: ""; property string label: ""; property bool active: false; signal clicked()
        spacing: 8; Layout.fillWidth: true
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 65; radius: 20
            color: active ? cAccent : cSurface; border.color: active ? cAccent : cBorder
            Text { anchors.centerIn: parent; text: icon; color: active ? cBg : cAccent; font.pixelSize: 24; font.family: "Symbols Nerd Font" }
            MouseArea { anchors.fill: parent; onClicked: parent.parent.clicked() }
        }
        Text { text: label; color: cDim; font.bold: true; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }
    }

    component PowerButton: Rectangle {
        property string btnText: ""; property string btnIcon: ""; property color btnColor: cSurface; property color txtColor: cText
        signal clicked(); Layout.fillWidth: true; height: 50; radius: 18; color: btnColor
        RowLayout {
            anchors.centerIn: parent; spacing: 12
            Text { text: btnIcon; color: txtColor; font.pixelSize: 18; font.family: "Symbols Nerd Font" }
            Text { text: btnText; color: txtColor; font.bold: true; font.pixelSize: 13 }
        }
        MouseArea { anchors.fill: parent; onClicked: parent.clicked() }
    }
}
