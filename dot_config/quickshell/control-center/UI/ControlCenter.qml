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

    // Fixed width, expands to fit content when hovered
    implicitWidth: 400
    implicitHeight: hoverHandler.hovered ? (contentCol.implicitHeight + 78) : 30  // Fixed minimum height

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
    readonly property color cYellow: "#fab387"

    color: "transparent"

    // The trigger area
    HoverHandler { id: hoverHandler }

    Rectangle {
        id: panel
        anchors.fill: parent
        anchors.leftMargin: 15
        anchors.rightMargin: 15
        anchors.topMargin: 15
        anchors.bottomMargin: 15  // Changed from -28 to 15 to prevent cutting off
        color: Qt.rgba(cBg.r, cBg.g, cBg.b, 0.95)  // Increased opacity for better visibility
        radius: 20  // Slightly less rounded
        border.color: Qt.rgba(1, 1, 1, 0.15)  // Slightly more visible border
        border.width: 1
        visible: opacity > 0
        opacity: hoverHandler.hovered ? 1.0 : 0.0
        clip: true

        // Add subtle shadow effect
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.3)
            shadowVerticalOffset: 5
            shadowBlur: 10
        }

        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.margins: 24
            spacing: 24

            // HEADER - Enhanced with better visual hierarchy
            RowLayout {
                spacing: 12
                Rectangle {
                    width: 45; height: 45; radius: 22.5; color: cSurface
                    border.color: cAccent; border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "" // User Icon
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 20; color: cAccent
                    }
                }
                ColumnLayout {
                    spacing: 2
                    Text {
                        text: SystemService.user;
                        color: cText;
                        font.bold: true;
                        font.pixelSize: 14
                    }
                    Text {
                        text: SystemService.uptime;
                        color: cDim;
                        font.pixelSize: 11;
                        font.italic: true  // Added italic for better distinction
                    }
                }
                Item { Layout.fillWidth: true }
                IconButton {
                    icon: "󰒓";
                    width: 36; height: 36;  // Slightly larger for better click area
                    onClicked: Quickshell.execDetached(["nm-connection-editor"])
                }
            }

            // QUICK TOGGLES - Improved layout
            GridLayout {
                columns: 4;  // Changed to 4 columns for better balance
                columnSpacing: 8;  // Reduced spacing
                rowSpacing: 8;
                Layout.fillWidth: true

                QuickTile {
                    label: "Wi-Fi"; icon: "󰖩"; active: QuickSettingsService.wifiEnabled
                    onClicked: QuickSettingsService.toggleWifi()
                }
                QuickTile {
                    label: "BT"; icon: "󰂯"; active: QuickSettingsService.btEnabled
                    onClicked: QuickSettingsService.toggleBluetooth()
                }
                QuickTile {
                    label: "Night"; icon: "󰖔"; active: QuickSettingsService.nightLightEnabled
                    onClicked: QuickSettingsService.toggleNightLight()
                }
                QuickTile {
                    label: "DND"; icon: "󰂚"; active: QuickSettingsService.dndEnabled
                    onClicked: QuickSettingsService.toggleDnd()
                }
            }

            // SLIDERS - Enhanced with better visual feedback
            ColumnLayout {
                spacing: 15; Layout.fillWidth: true
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
            RowLayout {
                Layout.fillWidth: true; spacing: 10
                StatPill {
                    value: Math.round(ResourceService.cpu) + "%";
                    icon: "";
                    accentColor: cRed
                }
                StatPill {
                    value: Math.round(ResourceService.ram) + "%";
                    icon: "";
                    accentColor: cYellow || "#fab387"
                }
                StatPill {
                    value: QuickSettingsService.batteryLevel + "%";
                    icon: "󰁹";
                    accentColor: cGreen || "#a6e3a1"
                }
            }
            }
        }

    // COMPONENTS
    component IconButton: Rectangle {
        property string icon: ""
        signal clicked()
        width: 32; height: 32; radius: 16; color: cSurface
        Text { anchors.centerIn: parent; text: icon; color: cText; font.pixelSize: 14; font.family: "Symbols Nerd Font" }
        MouseArea { anchors.fill: parent; hoverEnabled: true; onClicked: parent.clicked() }
    }

    component QuickTile: Rectangle {
        property string label: ""; property string icon: ""; property bool active: false
        signal clicked()
        Layout.fillWidth: true; height: 50; radius: 12
        color: active ? cAccent : cSurface
        border.width: 1
        border.color: active ? cAccent : Qt.rgba(1,1,1,0.1)
        
        RowLayout {
            anchors.fill: parent; anchors.margins: 10; spacing: 10
            Text { text: icon; color: active ? cBg : cAccent; font.pixelSize: 16; font.family: "Symbols Nerd Font" }
            Text { text: label; color: active ? cBg : cText; font.bold: true; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true }
        }
        MouseArea { anchors.fill: parent; onClicked: parent.clicked() }
    }

    component SliderModule: RowLayout {
        property string icon: ""; property real value: 0
        signal moved(real val); signal iconClicked()
        spacing: 10
        IconButton {
            icon: parent.icon; Layout.preferredWidth: 36; Layout.preferredHeight: 36
            onClicked: parent.iconClicked()
        }
        Slider {
            Layout.fillWidth: true; value: parent.value
            background: Rectangle {
                implicitHeight: 4; radius: 2; color: cSurface
                Rectangle { width: parent.parent.visualPosition * parent.width; height: parent.height; radius: 2; color: cAccent }
            }
            handle: Rectangle {
                x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                y: parent.topPadding + parent.availableHeight / 2 - height / 2
                width: 12; height: 12; radius: 6; color: "white"
            }
            onMoved: parent.moved(value)
        }
    }

    component StatPill: Rectangle {
        id: spRoot
        property string value: ""; property string icon: ""; property color accentColor: cAccent
        Layout.fillWidth: true
        height: 36
        radius: 18
        color: cSurface
        
        Row {
            anchors.centerIn: parent
            spacing: 8
            Text {
                text: spRoot.icon;
                color: spRoot.accentColor;
                font.pixelSize: 14;
                font.family: "Symbols Nerd Font"
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: spRoot.value;
                color: cText;
                font.bold: true;
                font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
