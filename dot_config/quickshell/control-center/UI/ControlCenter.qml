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
    
    // 1px height when hidden, expands to fit content when hovered
    implicitWidth: 400
    implicitHeight: hoverHandler.hovered ? (contentCol.implicitHeight + 80) : 1
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "control-center"

    readonly property color cBg: ThemeService.background
    readonly property color cSurface: ThemeService.surface
    readonly property color cAccent: ThemeService.accent
    readonly property color cText: ThemeService.text
    readonly property color cDim: ThemeService.text_dim
    readonly property color cRed: ThemeService.error

    color: "transparent"

    // The trigger area
    HoverHandler { id: hoverHandler }

    Rectangle {
        id: panel
        anchors.fill: parent
        anchors.leftMargin: 15
        anchors.rightMargin: 15
        anchors.topMargin: 15
        anchors.bottomMargin: -28 // Push the bottom rounded corners off-screen
        color: Qt.rgba(cBg.r, cBg.g, cBg.b, 0.85)
        radius: 28
        border.color: Qt.rgba(1, 1, 1, 0.1)
        border.width: 1
        visible: opacity > 0
        opacity: hoverHandler.hovered ? 1.0 : 0.0
        clip: true

        Behavior on opacity { NumberAnimation { duration: 200 } }

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.margins: 24
            spacing: 24

            // HEADER
            RowLayout {
                spacing: 15
                Rectangle {
                    width: 44; height: 44; radius: 22; color: cAccent
                    Text {
                        anchors.centerIn: parent
                        text: (SystemService.user && SystemService.user.length > 0) ? SystemService.user[0].toUpperCase() : "?"
                        font.bold: true; font.pixelSize: 18; color: cBg
                    }
                }
                ColumnLayout {
                    spacing: 0
                    Text { text: SystemService.user; color: cText; font.bold: true; font.pixelSize: 14 }
                    Text { text: SystemService.uptime; color: cDim; font.pixelSize: 10 }
                }
                Item { Layout.fillWidth: true }
                IconButton { icon: "󰒓"; onClicked: Quickshell.execDetached(["nm-connection-editor"]) }
            }

            // QUICK TOGGLES
            GridLayout {
                columns: 2; columnSpacing: 10; rowSpacing: 10
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
                    label: "DND"; icon: "󰂚"; active: QuickSettingsService.dndEnabled
                    onClicked: QuickSettingsService.toggleDnd()
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

            // STATS
            RowLayout {
                Layout.fillWidth: true; spacing: 15
                StatPill { value: Math.round(ResourceService.cpu) + "%"; icon: ""; color: "#f38ba8" }
                StatPill { value: Math.round(ResourceService.ram) + "%"; icon: ""; color: "#fab387" }
                StatPill { value: QuickSettingsService.batteryLevel + "%"; icon: "󰁹"; color: "#a6e3a1" }
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

    component StatPill: RowLayout {
        property string value: ""; property string icon: ""; property color color: cAccent
        spacing: 4
        Text { text: icon; color: parent.color; font.pixelSize: 11; font.family: "Symbols Nerd Font" }
        Text { text: value; color: cText; font.bold: true; font.pixelSize: 10 }
    }
}