import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "."
import "../Services"

PanelWindow {
    id: root
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "dashboard"

    property bool visible_state: false
    property bool powerMenuVisible: false
    Component.onCompleted: visible_state = true

    function close() { visible_state = false; exitTimer.start() }
    Timer { id: exitTimer; interval: 300; onTriggered: Qt.quit() }

    // --- Colors from Common ThemeService (Safe Access) ---
    // readonly property color cBg: (typeof Common.ThemeService !== "undefined" && Common.ThemeService.backgroundDark) ? Common.ThemeService.backgroundDark : "#0b0b12"
    readonly property color cCard: Qt.rgba(1, 1, 1, 0.04)
    // readonly property color cAccent: (typeof Common.ThemeService !== "undefined" && Common.ThemeService.accent) ? Common.ThemeService.accent : "#cba6f7"
    // readonly property color cText: (typeof Common.ThemeService !== "undefined" && Common.ThemeService.text) ? Common.ThemeService.text : "#cdd6f4"
    // readonly property color cDim: (typeof Common.ThemeService !== "undefined" && Common.ThemeService.text_dim) ? Common.ThemeService.text_dim : "#6c7086"
    readonly property color cBg: ThemeService.background
    readonly property color cSurface: ThemeService.surface
    readonly property color cAccent: ThemeService.accent
    readonly property color cText: ThemeService.text
    readonly property color cDim: ThemeService.text_dim


    // --- Background ---
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: visible_state ? 0.7 : 0
        Behavior on opacity { NumberAnimation { duration: 300 } }
        MouseArea { anchors.fill: parent; onClicked: root.close() }
        focus: true; Keys.onEscapePressed: root.close()
    }

    // --- Main Window ---
    Rectangle {
        id: mainWindow
        anchors.centerIn: parent
        width: 1100
        height: 650
        radius: 24
        clip: true

        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(cBg.r, cBg.g, cBg.b, 0.9) }
            GradientStop { position: 1.0; color: cBg }
        }
        border.width: 1
        border.color: Qt.rgba(1,1,1,0.1)

        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: false
            shadowEnabled: true
            shadowBlur: 0.6
            shadowOpacity: 0.4
        }

        transform: Scale {
            origin.x: 550; origin.y: 325
            xScale: visible_state ? 1 : 0.95
            yScale: visible_state ? 1 : 0.95
            Behavior on xScale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
            Behavior on yScale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
        }
        opacity: visible_state ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 300 } }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // --- Sidebar ---
            Rectangle {
                Layout.preferredWidth: 80
                Layout.fillHeight: true
                color: Qt.rgba(0,0,0,0.3)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.topMargin: 30
                    anchors.bottomMargin: 30
                    spacing: 20

                    TabButton {
                        icon: ""
                        active: stack.currentIndex === 0 && !powerMenuVisible
                        onClicked: { stack.currentIndex = 0; powerMenuVisible = false }
                    }
                    TabButton {
                        icon: ""
                        active: stack.currentIndex === 1 && !powerMenuVisible
                        onClicked: { stack.currentIndex = 1; powerMenuVisible = false }
                    }
                    TabButton {
                        icon: "󰃭"
                        active: stack.currentIndex === 2 && !powerMenuVisible
                        onClicked: { stack.currentIndex = 2; powerMenuVisible = false }
                    }

                    Item { Layout.fillHeight: true }

                    TabButton {
                        icon: ""
                        iconColor: "#f38ba8"
                        active: powerMenuVisible
                        onClicked: powerMenuVisible = !powerMenuVisible
                    }
                }
            }

            // --- Content Area ---
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                StackLayout {
                    id: stack
                    anchors.fill: parent
                    currentIndex: 0
                    opacity: powerMenuVisible ? 0.2 : 1
                    Behavior on opacity { NumberAnimation { duration: 300 } }

                    // 1. HOME
                    Item {
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 40; spacing: 40
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 30
                                ColumnLayout {
                                    Text { text: Qt.formatTime(new Date(), "HH:mm"); color: cText; font.pixelSize: 84; font.bold: true; font.family: "JetBrains Mono" }
                                    Text { text: Qt.formatDate(new Date(), "dddd, MMMM d"); color: cAccent; font.pixelSize: 22; font.bold: true }
                                }
                                Rectangle {
                                    width: 160; height: 60; radius: 30; color: cCard; border.width: 1; border.color: Qt.rgba(1,1,1,0.1)
                                    RowLayout {
                                        anchors.centerIn: parent; spacing: 12
                                        Text { text: (typeof WeatherService !== "undefined" ? WeatherService.icon : "󰖐") || "󰖐"; color: cText; font.pixelSize: 28; font.family: "Symbols Nerd Font" }
                                        Text { text: (typeof WeatherService !== "undefined" ? WeatherService.temp : "0°C") || "0°C"; color: cText; font.bold: true; font.pixelSize: 18 }
                                    }
                                }
                                GridLayout {
                                    columns: 2; columnSpacing: 20; rowSpacing: 20; Layout.fillWidth: true
                                    StatCard { icon: ""; label: "CPU"; value: (typeof ResourceService !== "undefined" ? Math.round(ResourceService.cpu) : 0) + "%"; statColor: "#f38ba8" }
                                    StatCard { icon: ""; label: "RAM"; value: (typeof ResourceService !== "undefined" ? Math.round(ResourceService.ram) : 0) + "%"; statColor: "#fab387" }
                                    StatCard { icon: "󰇚"; label: "Down"; value: (typeof ResourceService !== "undefined" ? ResourceService.netDown : "0B/s"); statColor: "#a6e3a1" }
                                    StatCard { icon: "󰕒"; label: "Up"; value: (typeof ResourceService !== "undefined" ? ResourceService.netUp : "0B/s"); statColor: "#89b4fa" }
                                }
                            }
                            Rectangle {
                                Layout.preferredWidth: 350; Layout.fillHeight: true; color: cCard; radius: 24; border.width: 1; border.color: Qt.rgba(1,1,1,0.1); clip: true
                                FullMediaPlayer { anchors.fill: parent; anchors.margins: 20 }
                            }
                        }
                    }

                    // 2. SYSTEM
                    Item {
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 40; spacing: 25
                            RowLayout {
                                Layout.fillWidth: true; Layout.fillHeight: true; spacing: 25
                                Rectangle {
                                    Layout.fillWidth: true; Layout.fillHeight: true; color: cCard; radius: 24
                                    ColumnLayout {
                                        anchors.centerIn: parent; spacing: 30
                                        RowLayout {
                                            spacing: 40
                                            MiniGauge { value: typeof ResourceService !== "undefined" ? ResourceService.cpu : 0; label: "CPU"; pillColor: "#f38ba8"; size: 120; strokeWidth: 12 }
                                            MiniGauge { value: typeof ResourceService !== "undefined" ? ResourceService.ram : 0; label: "RAM"; pillColor: "#fab387"; size: 120; strokeWidth: 12 }
                                            MiniGauge { value: typeof ResourceService !== "undefined" ? ResourceService.gpu : 0; label: "GPU"; pillColor: "#89b4fa"; size: 120; strokeWidth: 12 }
                                        }
                                        RowLayout {
                                            Layout.alignment: Qt.AlignHCenter; spacing: 40
                                            StatMini { icon: "󰋊"; label: "Disk"; value: typeof ResourceService !== "undefined" ? ResourceService.disk : "0%"; statMiniColor: "#a6e3a1" }
                                            StatMini { icon: ""; label: "Temp"; value: (typeof ResourceService !== "undefined" ? Math.round(ResourceService.cpuTemp) : 0) + "°C"; statMiniColor: "#f9e2af" }
                                        }
                                    }
                                }
                                Rectangle {
                                    Layout.preferredWidth: 350; Layout.fillHeight: true; color: cCard; radius: 24
                                    ColumnLayout {
                                        anchors.fill: parent; anchors.margins: 25; spacing: 15
                                        Text { text: "System Information"; color: cText; font.bold: true; font.pixelSize: 18 }
                                        Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.1) }
                                        InfoLine { label: "OS"; value: "Arch Linux"; icon: "󰣇" }
                                        InfoLine { label: "Kernel"; value: (typeof SystemService !== "undefined" ? SystemService.kernelVersion : "Linux") || "Linux"; icon: "" }
                                        InfoLine { label: "Uptime"; value: (typeof SystemService !== "undefined" ? SystemService.uptime : "0m") || "0m"; icon: "󰅐" }
                                        InfoLine { label: "Shell"; value: "zsh 5.9"; icon: "" }
                                        InfoLine { label: "WM"; value: "Hyprland"; icon: "" }
                                        Item { Layout.fillHeight: true }
                                        Rectangle {
                                            Layout.fillWidth: true; height: 60; radius: 15; color: Qt.rgba(1,1,1,0.05)
                                            RowLayout {
                                                anchors.centerIn: parent; spacing: 20
                                                Text { text: "󰖩 " + (typeof QuickSettingsService !== "undefined" && QuickSettingsService.wifiEnabled ? "Online" : "Offline"); color: (typeof QuickSettingsService !== "undefined" && QuickSettingsService.wifiEnabled) ? "#a6e3a1" : "#f38ba8"; font.bold: true; font.pixelSize: 12; font.family: "Symbols Nerd Font" }
                                                Text { text: "󰁹 " + (typeof QuickSettingsService !== "undefined" ? QuickSettingsService.batteryLevel : 0) + "%"; color: "#f9e2af"; font.bold: true; font.pixelSize: 12; font.family: "Symbols Nerd Font" }
                                            }
                                        }
                                    }
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 120; color: cCard; radius: 24
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 25; spacing: 20
                                    Rectangle { width: 70; height: 70; radius: 35; clip: true; Image { source: "file:///home/zoro/.face"; anchors.fill: parent; fillMode: Image.PreserveAspectCrop } }
                                    ColumnLayout {
                                        Text { text: typeof SystemService !== "undefined" ? SystemService.user : "User"; color: cText; font.bold: true; font.pixelSize: 22 }
                                        Text { text: typeof SystemService !== "undefined" ? SystemService.hostname : "Host"; color: cDim; font.pixelSize: 14 }
                                    }
                                    Item { Layout.fillWidth: true }
                                }
                            }
                        }
                    }

                    // 3. CALENDAR
                    CalendarView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                }

                // --- SLIDING POWER MENU ---
                Rectangle {
                    id: powerPanel
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 140
                    color: Qt.rgba(0,0,0,0.4)
                    border.width: 1
                    border.color: Qt.rgba(1,1,1,0.1)

                    x: powerMenuVisible ? parent.width - width : parent.width
                    Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.topMargin: 50
                        anchors.bottomMargin: 50
                        spacing: 25

                        PowerActionMini {
                            icon: "󰌾"
                            label: "Lock"
                            color: cAccent
                            action: function() { if (typeof QuickSettingsService !== "undefined") QuickSettingsService.lock(); root.close() }
                        }
                        PowerActionMini {
                            icon: "󰤄"
                            label: "Sleep"
                            color: "#89b4fa"
                            action: function() { Quickshell.execDetached(["systemctl", "suspend"]); root.close() }
                        }
                        PowerActionMini {
                            icon: "󰑓"
                            label: "Reboot"
                            color: "#fab387"
                            action: function() { if (typeof QuickSettingsService !== "undefined") QuickSettingsService.reboot() }
                        }
                        PowerActionMini {
                            icon: "󰐥"
                            label: "Power"
                            color: "#f38ba8"
                            action: function() { if (typeof QuickSettingsService !== "undefined") QuickSettingsService.shutdown() }
                        }

                        Item { Layout.fillHeight: true }

                        PowerActionMini {
                            icon: "󰅖"
                            label: "Back"
                            color: cText
                            action: function() { powerMenuVisible = false }
                        }
                    }
                }
            }
        }
    }

    // --- Components ---

    component TabButton: Rectangle {
        property string icon: ""
        property bool active: false
        property color iconColor: active ? cAccent : cDim
        signal clicked()

        width: 50
        height: 50
        radius: 12
        color: active ? Qt.rgba(ThemeService.accent.r, ThemeService.accent.g, ThemeService.accent.b, 0.1) : "transparent"
        border.color: active ? ThemeService.accent : "transparent"
        border.width: 1
        Layout.alignment: Qt.AlignHCenter

        Text {
            anchors.centerIn: parent
            text: icon
            color: parent.iconColor
            font.pixelSize: 24
            font.family: "Symbols Nerd Font"
        }
        MouseArea {
            anchors.fill: parent
            onClicked: parent.clicked()
            hoverEnabled: true
        }
    }

    component StatCard: Rectangle {
        property string icon: ""
        property string label: ""
        property string value: ""
        property color statColor: ThemeService.accent

        Layout.fillWidth: true
        height: 90
        radius: 18
        color: cCard

        RowLayout {
            anchors.centerIn: parent
            spacing: 15
            Rectangle {
                width: 44
                height: 44
                radius: 22
                color: Qt.rgba(parent.statColor.r, parent.statColor.g, parent.statColor.b, 0.2)
                Text {
                    anchors.centerIn: parent
                    text: icon
                    color: parent.parent.statColor
                    font.pixelSize: 22
                    font.family: "Symbols Nerd Font"
                }
            }
            ColumnLayout {
                spacing: 2
                Text {
                    text: label
                    color: cDim
                    font.pixelSize: 11
                    font.bold: true
                }
                Text {
                    text: value
                    color: cText
                    font.pixelSize: 18
                    font.bold: true
                }
            }
        }
    }

    component StatMini: RowLayout {
        property string icon: ""
        property string label: ""
        property string value: ""
        property color statMiniColor: ThemeService.accent

        spacing: 10
        Text {
            text: icon
            color: parent.statMiniColor
            font.pixelSize: 18
            font.family: "Symbols Nerd Font"
        }
        ColumnLayout {
            spacing: 0
            Text {
                text: label
                color: cDim
                font.pixelSize: 9
                font.bold: true
            }
            Text {
                text: value
                color: cText
                font.pixelSize: 13
                font.bold: true
            }
        }
    }

    component InfoLine: RowLayout {
        property string label: ""
        property string value: ""
        property string icon: ""

        Layout.fillWidth: true
        spacing: 12
        Text {
            text: icon
            color: ThemeService.accent
            font.pixelSize: 14
            font.family: "Symbols Nerd Font"
            Layout.preferredWidth: 20
        }
        Text {
            text: label
            color: cDim
            font.pixelSize: 11
            font.bold: true
            Layout.fillWidth: true
        }
        Text {
            text: value
            color: cText
            font.pixelSize: 11
            font.bold: true
            Layout.alignment: Qt.AlignRight
        }
    }

    component PowerActionMini: ColumnLayout {
        property string icon: ""
        property string label: ""
        property color color: cText
        property var action: null

        spacing: 8
        Layout.alignment: Qt.AlignHCenter

        Rectangle {
            width: 70
            height: 70
            radius: 20
            color: Qt.rgba(1,1,1,0.03)
            border.color: hover.hovered ? ThemeService.accent : "transparent"
            border.width: 1
            Text {
                anchors.centerIn: parent
                text: icon
                color: parent.parent.color
                font.pixelSize: 32
                font.family: "Symbols Nerd Font"
            }
            MouseArea {
                anchors.fill: parent
                onClicked: { if (parent.parent.action) parent.parent.action() }
            }
            HoverHandler { id: hover }
            scale: hover.hovered ? 1.05 : 1.0
            Behavior on scale { NumberAnimation { duration: 200 } }
        }
        Text {
            text: label
            color: cText
            font.pixelSize: 11
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
            opacity: hover.hovered ? 1 : 0.6
        }
    }
}
