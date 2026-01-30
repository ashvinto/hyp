import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
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

    readonly property color cBg: ThemeService.backgroundDark
    readonly property color cCard: ThemeService.surface
    readonly property color cSurface: ThemeService.surface_variant
    readonly property color cBorder: ThemeService.surface_variant
    readonly property color cText: ThemeService.text
    readonly property color cAccent: ThemeService.accent
    readonly property color cDim: ThemeService.text_dim
    readonly property color cGreen: ThemeService.success
    readonly property color cRed: ThemeService.error

    property var currentTime: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: { root.currentTime = new Date(); if (root.visible) WorkspaceService.update() } }

    Rectangle {
        anchors.fill: parent; color: "#dd000000"
        MouseArea { anchors.fill: parent; onClicked: Qt.quit() }
        focus: true; Keys.onEscapePressed: Qt.quit()

        GridLayout {
            anchors.centerIn: parent; columns: 3; rows: 2; columnSpacing: 24; rowSpacing: 24; width: 1150

            Rectangle {
                Layout.preferredWidth: 340; Layout.preferredHeight: 320; color: cCard; radius: 32; border.color: cBorder; border.width: 1
                ColumnLayout {
                    anchors.centerIn: parent; spacing: 20
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 90; height: 90; radius: 45
                        color: cAccent
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: cAccent }
                            GradientStop { position: 1.0; color: Qt.darker(cAccent, 1.2) }
                        }
                        Text {
                            anchors.centerIn: parent
                            text: SystemService.user[0].toUpperCase()
                            font.pixelSize: 38
                            font.bold: true
                            color: cBg
                        }
                    }
                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 4
                        Text {
                            text: SystemService.greeting
                            color: cDim
                            font.pixelSize: 13
                            font.letterSpacing: 1
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            text: SystemService.user
                            color: cText
                            font.pixelSize: 22
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 24
                        ColumnLayout {
                            spacing: 2
                            Text {
                                text: "Uptime"
                                color: cDim
                                font.pixelSize: 10
                                font.bold: true
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: SystemService.uptime
                                color: cAccent
                                font.pixelSize: 12
                                font.bold: true
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                        Rectangle {
                            width: 1; height: 24
                            color: cBorder
                        }
                        ColumnLayout {
                            spacing: 2
                            Text {
                                text: "OS Age"
                                color: cDim
                                font.pixelSize: 10
                                font.bold: true
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: SystemService.osAge
                                color: cAccent
                                font.pixelSize: 12
                                font.bold: true
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 340
                Layout.preferredHeight: 320
                color: cCard
                radius: 32
                border.color: cBorder
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                        text: Qt.formatTime(root.currentTime, "HH:mm:ss")
                        color: cText
                        font.pixelSize: 62
                        font.bold: true
                        font.family: "JetBrains Mono"
                    }
                    Text {
                        text: Qt.formatDate(root.currentTime, "dddd, MMMM d")
                        color: cAccent
                        font.pixelSize: 16
                        font.letterSpacing: 1.5
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 340
                Layout.preferredHeight: 320
                color: cCard
                radius: 32
                border.color: cBorder
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 28
                    spacing: 20
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Workspaces"
                            color: cDim
                            font.bold: true
                            font.pixelSize: 13
                            font.letterSpacing: 1
                            Layout.fillWidth: true
                        }
                        AnimatedImage {
                            source: "../assets/bongocat.gif"
                            width: 40; height: 40
                            fillMode: Image.PreserveAspectFit
                        }
                    }
                    Flow {
                        Layout.fillWidth: true
                        spacing: 12
                        Repeater {
                            model: WorkspaceService.workspaces
                            delegate: Rectangle {
                                width: 44
                                height: 44
                                radius: 14
                                color: modelData.id === WorkspaceService.activeId ? cAccent : cSurface
                                border.color: modelData.id === WorkspaceService.activeId ? cAccent : cBorder
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.id
                                    color: modelData.id === WorkspaceService.activeId ? cBg : cText
                                    font.bold: true
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: WorkspaceService.goTo(modelData.id)
                                }
                            }
                        }
                    }
                    Item {
                        Layout.fillHeight: true
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 64
                        color: cSurface
                        radius: 18
                        border.color: cBorder
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 14
                            Text {
                                text: QuickSettingsService.isCharging ? "󱐋" : "󰁹"
                                color: QuickSettingsService.isCharging ? cGreen : cAccent
                                font.pixelSize: 26
                            }
                            ColumnLayout {
                                spacing: 0
                                Text {
                                    text: QuickSettingsService.isCharging ? "Charging" : "Battery"
                                    color: cDim
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                                Text {
                                    text: QuickSettingsService.batteryLevel + "%"
                                    color: cText
                                    font.pixelSize: 18
                                    font.bold: true
                                }
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            Rectangle {
                                width: 60
                                height: 22
                                radius: 11
                                // Using rgba directly to avoid undefined errors
                                color: QuickSettingsService.batteryLevel > 20 ? "#26a6e3a1" : "#26f38ba8"
                                Text {
                                    anchors.centerIn: parent
                                    text: QuickSettingsService.batteryLevel > 20 ? "Good" : "Low"
                                    color: QuickSettingsService.batteryLevel > 20 ? cGreen : cRed
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 340
                Layout.preferredHeight: 340
                color: cCard
                radius: 32
                border.color: cBorder
                clip: true
                FullMediaPlayer {
                    anchors.centerIn: parent
                    width: parent.width - 30
                }
            }

            Rectangle {
                Layout.preferredWidth: 340
                Layout.preferredHeight: 340
                color: cCard
                radius: 32
                border.color: cBorder
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 15
                    Text {
                        text: "Resources"
                        color: cDim
                        font.bold: true
                        font.pixelSize: 13
                        font.letterSpacing: 1
                        Layout.leftMargin: 10
                    }
                    GridLayout {
                        columns: 3
                        columnSpacing: 8
                        rowSpacing: 12
                        Layout.fillWidth: true
                        ResourceGauge {
                            label: "CPU"
                            value: ResourceService.cpu
                            color: "#f38ba8"
                            size: 75
                        }
                        ResourceGauge {
                            label: "C-Temp"
                            value: ResourceService.cpuTemp
                            color: "#eba0ac"
                            size: 75
                            suffix: "°"
                        }
                        ResourceGauge {
                            label: "RAM"
                            value: ResourceService.ram
                            color: "#fab387"
                            size: 75
                        }
                        ResourceGauge {
                            label: "GPU"
                            value: ResourceService.gpu
                            color: "#89b4fa"
                            size: 75
                        }
                        ResourceGauge {
                            label: "G-Temp"
                            value: ResourceService.gpuTemp
                            color: "#74c7ec"
                            size: 75
                            suffix: "°"
                        }
                        ResourceGauge {
                            label: "Disk"
                            value: parseFloat(ResourceService.disk)
                            color: "#a6e3a1"
                            size: 75
                        }
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 340
                Layout.preferredHeight: 340
                color: cCard
                radius: 32
                border.color: cBorder
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 28
                    spacing: 20
                    Text {
                        text: "System"
                        color: cDim
                        font.bold: true
                        font.pixelSize: 13
                        font.letterSpacing: 1
                    }
                    RowLayout {
                        spacing: 14
                        Layout.alignment: Qt.AlignHCenter
                        SystemButton {
                            icon: "󰖩"
                            active: QuickSettingsService.wifiEnabled
                            onClicked: QuickSettingsService.toggleWifi()
                        }
                        SystemButton {
                            icon: "󰂯"
                            active: QuickSettingsService.btEnabled
                            onClicked: QuickSettingsService.toggleBluetooth()
                        }
                        SystemButton {
                            icon: "󰌾"
                            active: false
                            onClicked: QuickSettingsService.lock()
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: cBorder
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        PowerButton {
                            btnText: "Logout"
                            btnIcon: "󰍃"
                            btnColor: cSurface
                            txtColor: cText
                            onClicked: QuickSettingsService.logout()
                        }
                        PowerButton {
                            btnText: "Reboot"
                            btnIcon: "󰑓"
                            btnColor: cSurface
                            txtColor: cText
                            onClicked: QuickSettingsService.reboot()
                        }
                        PowerButton {
                            btnText: "Shutdown"
                            btnIcon: "󰐥"
                            btnColor: cRed
                            txtColor: cBg
                            onClicked: QuickSettingsService.shutdown()
                        }
                    }
                }
            }
        }
    }

    component ResourceGauge: ColumnLayout {
        property string label: ""
        property real value: 0
        property color color: cAccent
        property real size: 80
        property string suffix: "%"
        spacing: 6
        Layout.alignment: Qt.AlignHCenter

        Item {
            width: size
            height: size
            Layout.alignment: Qt.AlignHCenter

            Shape {
                anchors.fill: parent
                layer.enabled: true
                layer.samples: 4

                ShapePath {
                    strokeColor: cSurface
                    strokeWidth: 5
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap

                    PathAngleArc {
                        centerX: size/2
                        centerY: size/2
                        radiusX: size/2-8
                        radiusY: size/2-8
                        startAngle: -90
                        sweepAngle: 360
                    }
                }

                ShapePath {
                    strokeColor: parent.parent.color
                    strokeWidth: 5
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap

                    PathAngleArc {
                        centerX: size/2
                        centerY: size/2
                        radiusX: size/2-8
                        radiusY: size/2-8
                        startAngle: -90
                        sweepAngle: (Math.min(value, 100) / 100) * 360

                        Behavior on sweepAngle {
                            NumberAnimation {
                                duration: 1000
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: Math.round(value) + suffix
                color: cText
                font.pixelSize: size/5
                font.bold: true
                font.family: "JetBrains Mono"
            }
        }

        Text {
            text: label
            color: cDim
            font.pixelSize: 10
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }
    }

    component SystemButton: Rectangle {
        property string icon: ""
        property bool active: false
        signal clicked()
        width: 60
        height: 60
        radius: 18
        color: active ? cAccent : cSurface
        border.color: active ? cAccent : cBorder

        Text {
            anchors.centerIn: parent
            text: icon
            color: active ? cBg : cText
            font.pixelSize: 24
        }

        MouseArea {
            anchors.fill: parent
            onClicked: parent.clicked()
        }
    }

    component PowerButton: Rectangle {
        property string btnText: ""
        property string btnIcon: ""
        property color btnColor: cSurface
        property color txtColor: cText
        signal clicked()
        Layout.fillWidth: true
        height: 44
        radius: 14
        color: btnColor

        RowLayout {
            anchors.centerIn: parent
            spacing: 10

            Text {
                text: btnIcon
                color: txtColor
                font.pixelSize: 18
            }

            Text {
                text: btnText
                color: txtColor
                font.bold: true
                font.pixelSize: 13
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: parent.clicked()
        }
    }
}