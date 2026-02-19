import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../Services"

PanelWindow {
    id: root

    // Anchor ONLY to bottom-right
    anchors.bottom: true
    anchors.right: true

    // Fixed width, reduced to fit content snugly
    implicitWidth: 360
    implicitHeight: hoverHandler.hovered ? (contentCol.implicitHeight + 40) : 30

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "control-center"

    readonly property color cBg: ThemeService.background
    readonly property color cSurface: ThemeService.surface
    readonly property color cAccent: ThemeService.accent
    readonly property color cText: ThemeService.text
    readonly property color cDim: ThemeService.text_dim
    readonly property color cRed: ThemeService.error
    readonly property color cGreen: ThemeService.success
    readonly property color cBlue: "#89b4fa"
    readonly property color cYellow: "#fab387"

    color: "transparent"

    // The trigger area
    HoverHandler { id: hoverHandler }

    Rectangle {
        id: panel
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.topMargin: 10
        anchors.rightMargin: 0
        anchors.bottomMargin: 0
        color: Qt.rgba(cBg.r, cBg.g, cBg.b, 0.98)
        radius: 24
        border.color: Qt.rgba(1, 1, 1, 0.1)
        border.width: 1
        visible: opacity > 0
        opacity: hoverHandler.hovered ? 1.0 : 0.0

        // Add subtle shadow effect
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.4)
            shadowVerticalOffset: 4
            shadowBlur: 15
        }

        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            anchors.topMargin: 24
            anchors.bottomMargin: 24
            spacing: 24

            // HEADER
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Rectangle {
                    width: 44; height: 44; radius: 22; color: cSurface
                    clip: true
                    border.color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.3); border.width: 1
                    
                    Image {
                        source: (typeof ConfigService !== "undefined") ? ConfigService.profileIcon : "file:///home/zoro/.face"
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        onStatusChanged: if (status == Image.Error) fallbackIcon.visible = true
                    }
                    Text {
                        id: fallbackIcon
                        anchors.centerIn: parent
                        text: (SystemService.user && SystemService.user.length > 0) ? SystemService.user[0].toUpperCase() : "?"
                        font.bold: true; font.pixelSize: 18; color: cAccent
                        visible: false
                    }
                }
                ColumnLayout {
                    spacing: 0
                    Text {
                        text: SystemService.user;
                        color: cText;
                        font.bold: true;
                        font.pixelSize: 15
                    }
                    Text {
                        text: SystemService.uptime;
                        color: cDim;
                        font.pixelSize: 12;
                    }
                }
                Item { Layout.fillWidth: true }
                IconButton {
                    icon: "󰒓";
                    onClicked: Quickshell.execDetached(["nm-connection-editor"])
                }
            }

            // QUICK TOGGLES
            GridLayout {
                columns: 2
                columnSpacing: 10
                rowSpacing: 10
                Layout.fillWidth: true

                QuickTile {
                    label: "Wi-Fi"; icon: "󰖩"; active: QuickSettingsService.wifiEnabled
                    onClicked: QuickSettingsService.toggleWifi()
                }
                QuickTile {
                    label: "Bluetooth"; icon: "󰂯"; active: QuickSettingsService.btEnabled
                    onClicked: QuickSettingsService.toggleBluetooth()
                }
                QuickTile {
                    label: "Night Light"; icon: "󰖔"; active: QuickSettingsService.nightLightEnabled
                    onClicked: QuickSettingsService.toggleNightLight()
                }
                QuickTile {
                    label: "DND Mode"; icon: "󰂚"; active: QuickSettingsService.dndEnabled
                    onClicked: QuickSettingsService.toggleDnd()
                }
                QuickTile {
                    label: "Focus Mode"; icon: "󰈉"; active: QuickSettingsService.focusModeEnabled
                    onClicked: QuickSettingsService.toggleFocus()
                }
                QuickTile {
                    label: "Retro Mode"; icon: "󰄭"; active: QuickSettingsService.retroModeEnabled
                    onClicked: QuickSettingsService.toggleRetro()
                }
            }

            // SLIDERS
            ColumnLayout {
                spacing: 12; Layout.fillWidth: true
                SliderModule {
                    icon: VolumeService.muted ? "󰝟" : "󰕾"
                    value: VolumeService.volume / 100
                    onMoved: (v) => VolumeService.setVolume(Math.round(v * 100))
                    onIconClicked: VolumeService.toggleMute()
                }
                SliderModule {
                    icon: "󰃠"
                    value: BrightnessService.brightness / 100
                    onMoved: (v) => BrightnessService.setBrightness(Math.round(v * 100))
                }
            }

            // SYSTEM MONITOR SECTION
            Rectangle {
                Layout.fillWidth: true
                height: statsGrid.implicitHeight + 30
                color: cSurface
                radius: 16
                border.color: Qt.rgba(1, 1, 1, 0.05)

                GridLayout {
                    id: statsGrid
                    anchors.centerIn: parent
                    width: parent.width - 20
                    columns: 3
                    columnSpacing: 10
                    rowSpacing: 15

                    StatPill {
                        label: "CPU"
                        value: Math.round(ResourceService.cpu) + "%"
                        icon: ""
                        pillColor: cRed
                    }
                    StatPill {
                        label: "RAM"
                        value: Math.round(ResourceService.ram) + "%"
                        icon: ""
                        pillColor: cYellow
                    }
                    StatPill {
                        label: "BAT"
                        value: QuickSettingsService.batteryLevel + "%"
                        icon: "󰁹"
                        pillColor: cGreen
                    }
                    StatPill {
                        label: "GPU"
                        value: Math.round(ResourceService.gpu) + "%"
                        icon: "󰢽"
                        pillColor: cBlue
                    }
                    StatPill {
                        label: "DISK"
                        value: ResourceService.disk
                        icon: "󱛟"
                        pillColor: cAccent
                    }
                    StatPill {
                        label: "TEMP"
                        value: Math.round(ResourceService.cpuTemp) + "°C"
                        icon: ""
                        pillColor: ResourceService.cpuTemp > 70 ? cRed : cYellow
                    }
                }
            }
        }
    }
}
