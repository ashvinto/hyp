import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../Services"

PanelWindow {
    id: root
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "settings"

    // --- Colors ---
    readonly property color cBg: (typeof ThemeService !== "undefined" && ThemeService.backgroundDark) ? ThemeService.backgroundDark : "#11111b"
    readonly property color cSurface: (typeof ThemeService !== "undefined" && ThemeService.surface) ? ThemeService.surface : "#1e1e2e"
    readonly property color cAccent: (typeof ThemeService !== "undefined" && ThemeService.accent) ? ThemeService.accent : "#cba6f7"
    readonly property color cText: (typeof ThemeService !== "undefined" && ThemeService.text) ? ThemeService.text : "#cdd6f4"
    readonly property color cDim: (typeof ThemeService !== "undefined" && ThemeService.text_dim) ? ThemeService.text_dim : "#6c7086"
    readonly property color cRed: (typeof ThemeService !== "undefined" && ThemeService.error) ? ThemeService.error : "#f38ba8"

    property bool active: false
    Component.onCompleted: active = true

    function close() { active = false; exitTimer.start() }
    Timer { id: exitTimer; interval: 300; onTriggered: Qt.quit() }

    MouseArea { anchors.fill: parent; z: -1; onClicked: root.close() }

    Rectangle {
        id: container
        anchors.centerIn: parent
        width: 850
        height: 620
        radius: 28
        clip: true

        color: Qt.rgba(cBg.r, cBg.g, cBg.b, 0.98)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.1)

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true; shadowBlur: 0.8; shadowOpacity: 0.5; shadowVerticalOffset: 10
        }

        opacity: active ? 1 : 0
        scale: active ? 1 : 0.98
        Behavior on opacity { NumberAnimation { duration: 300 } }
        Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // --- Sidebar ---
            Rectangle {
                Layout.preferredWidth: 200
                Layout.fillHeight: true
                color: Qt.rgba(0, 0, 0, 0.15)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 10

                    Text {
                        text: "PREFERENCES"
                        color: cAccent; font.bold: true; font.pixelSize: 10; font.letterSpacing: 1.5
                    }
                    Item { Layout.preferredHeight: 10 }

                    SidebarItem { icon: "󰃟"; label: "Appearance"; active: stack.currentIndex === 0; onClicked: stack.currentIndex = 0 }
                    SidebarItem { icon: "󰏘"; label: "Theme"; active: stack.currentIndex === 1; onClicked: stack.currentIndex = 1 }
                    SidebarItem { icon: "󰄭"; label: "Tools"; active: stack.currentIndex === 2; onClicked: stack.currentIndex = 2 }
                    SidebarItem { icon: "󰋙"; label: "About Me"; active: stack.currentIndex === 3; onClicked: stack.currentIndex = 3 }

                    Item { Layout.fillHeight: true }
                    Text { text: "v1.1.0 - Zoro"; color: cDim; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }
                }
            }

            // --- Main Content ---
            ColumnLayout {
                Layout.fillWidth: true; Layout.fillHeight: true; spacing: 0

                // Header
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 70; color: "transparent"
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 30; anchors.rightMargin: 30
                        Text {
                            text: {
                                switch(stack.currentIndex) {
                                    case 0: return "Appearance"
                                    case 1: return "Theme"
                                    case 2: return "Tools"
                                    case 3: return "About Me"
                                    default: return ""
                                }
                            }
                            color: cText; font.bold: true; font.pixelSize: 20
                        }
                        Item { Layout.fillWidth: true }
                        IconButton { icon: "󰅖"; onClicked: root.close() }
                    }
                }

                StackLayout {
                    id: stack
                    Layout.fillWidth: true; Layout.fillHeight: true

                    // --- APPEARANCE & SYSTEM (0) ---
                    SettingsPage {
                        title: "System Look & Behavior"
                        ColumnLayout {
                            width: parent.width
                            spacing: 25

                            Text { text: "SHELL INTERFACE"; color: cDim; font.bold: true; font.pixelSize: 9; font.letterSpacing: 1 }
                            RowLayout {
                                spacing: 15; Layout.fillWidth: true
                                SettingSwitch { label: "Zen Mode"; icon: "󰚀"; active: typeof ConfigService !== "undefined" ? ConfigService.zenMode : false; onClicked: if (typeof ConfigService !== "undefined") ConfigService.toggleZen() }
                                SettingSwitch { label: "Taskbar"; icon: "󰮇"; active: typeof ConfigService !== "undefined" ? ConfigService.showTaskbar : true; onClicked: if (typeof ConfigService !== "undefined") ConfigService.showTaskbar = !ConfigService.showTaskbar }
                            }

                            Text { text: "HYPRLAND EFFECTS"; color: cDim; font.bold: true; font.pixelSize: 9; font.letterSpacing: 1 }
                            RowLayout {
                                spacing: 15; Layout.fillWidth: true
                                SettingSwitch { label: "Blur"; icon: "󰃟"; active: typeof ConfigService !== "undefined" ? ConfigService.hyprBlur : true; onClicked: if (typeof ConfigService !== "undefined") ConfigService.hyprBlur = !ConfigService.hyprBlur }
                                SettingSwitch { label: "Animations"; icon: "󰚀"; active: typeof ConfigService !== "undefined" ? ConfigService.hyprAnimations : true; onClicked: if (typeof ConfigService !== "undefined") ConfigService.hyprAnimations = !ConfigService.hyprAnimations }
                            }

                            Text { text: "GEOMETRY & OPACITY"; color: cDim; font.bold: true; font.pixelSize: 9; font.letterSpacing: 1 }
                            ColumnLayout {
                                spacing: 15; Layout.fillWidth: true
                                SettingSlider { label: "Rounding"; icon: "󰃠"; value: typeof ConfigService !== "undefined" ? ConfigService.hyprRounding / 30 : 0.4; onMoved: (v) => { if (typeof ConfigService !== "undefined") ConfigService.hyprRounding = Math.round(v * 30) } }
                                SettingSlider { label: "Border Size"; icon: "󰗘"; value: typeof ConfigService !== "undefined" ? ConfigService.hyprBorderSize / 10 : 0.2; onMoved: (v) => { if (typeof ConfigService !== "undefined") ConfigService.hyprBorderSize = Math.round(v * 10) } }
                                SettingSlider { label: "Inner Gaps"; icon: "󰖲"; value: typeof ConfigService !== "undefined" ? ConfigService.hyprGapsIn / 20 : 0.25; onMoved: (v) => { if (typeof ConfigService !== "undefined") ConfigService.hyprGapsIn = Math.round(v * 20) } }
                                SettingSlider { label: "Outer Gaps"; icon: "󰖳"; value: typeof ConfigService !== "undefined" ? ConfigService.hyprGapsOut / 40 : 0.25; onMoved: (v) => { if (typeof ConfigService !== "undefined") ConfigService.hyprGapsOut = Math.round(v * 40) } }
                                SettingSlider { label: "Active Opacity"; icon: "󰃟"; value: typeof ConfigService !== "undefined" ? ConfigService.hyprOpacityActive : 1.0; onMoved: (v) => { if (typeof ConfigService !== "undefined") ConfigService.hyprOpacityActive = v } }
                            }

                            Text { text: "INPUT & HARDWARE"; color: cDim; font.bold: true; font.pixelSize: 9; font.letterSpacing: 1 }
                            ColumnLayout {
                                spacing: 15; Layout.fillWidth: true
                                SettingSlider { 
                                    label: "Mouse Sensitivity"; icon: "󰍽"
                                    value: typeof ConfigService !== "undefined" ? (ConfigService.mouseSensitivity + 1) / 2 : 0.5 
                                    onMoved: (v) => { if (typeof ConfigService !== "undefined") ConfigService.mouseSensitivity = (v * 2) - 1 }
                                }
                                SettingSwitch { 
                                    label: "Natural Scroll"; icon: "󰃟"
                                    active: typeof ConfigService !== "undefined" ? ConfigService.naturalScroll : false
                                    onClicked: if (typeof ConfigService !== "undefined") ConfigService.naturalScroll = !ConfigService.naturalScroll
                                }
                                SettingSlider { label: "Night Light"; icon: "󰖔"; value: typeof ConfigService !== "undefined" ? (ConfigService.nightLightWarmth - 1000) / 5500 : 1; onMoved: (v) => { if (typeof ConfigService !== "undefined") ConfigService.setNightLight(1000 + (v * 5500)) } }
                                SettingSlider { label: "Brightness"; icon: "󰃞"; value: typeof ConfigService !== "undefined" ? ConfigService.softwareDim : 1; onMoved: (v) => { if (typeof ConfigService !== "undefined") ConfigService.setDimming(v) } }
                            }

                            Text { text: "MAINTENANCE"; color: cDim; font.bold: true; font.pixelSize: 9; font.letterSpacing: 1 }
                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 40; radius: 10; color: relH.hovered ? cRed : cSurface
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 10; spacing: 10
                                    Text { text: "󰑓"; color: relH.hovered ? "black" : cRed; font.pixelSize: 14; font.family: "Symbols Nerd Font" }
                                    Text { text: "Reload Quickshell"; color: relH.hovered ? "black" : cText; font.bold: true; font.pixelSize: 11; Layout.fillWidth: true }
                                }
                                MouseArea { id: relA; anchors.fill: parent; onClicked: if (typeof ConfigService !== "undefined") ConfigService.reloadShell() } HoverHandler { id: relH }
                            }
                        }
                    }

                    // --- THEME (1) ---
                    SettingsPage {
                        title: "Color Customization"
                        ColumnLayout {
                            width: parent.width; spacing: 25
                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 50; radius: 12; color: syncHover.hovered ? cAccent : cSurface
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 15; spacing: 12
                                    Text { text: "󰸉"; color: syncHover.hovered ? "black" : cAccent; font.pixelSize: 18; font.family: "Symbols Nerd Font" }
                                    Text { text: "Sync with Wallpaper"; color: syncHover.hovered ? "black" : cText; font.bold: true; font.pixelSize: 13; Layout.fillWidth: true }
                                }
                                MouseArea { id: syncArea; anchors.fill: parent; onClicked: wallustProc.running = true }
                                HoverHandler { id: syncHover }
                            }
                            Process { id: wallustProc; command: ["bash", "-c", "wallust run \"$(cat /home/zoro/.cache/current_wallpaper)\""]; onExited: if (typeof ThemeService !== "undefined") ThemeService.updateColors() }
                            Text { text: "PRESET ACCENTS"; color: cDim; font.bold: true; font.pixelSize: 9 }
                            GridLayout {
                                columns: 5; columnSpacing: 15; rowSpacing: 15
                                Repeater {
                                    model: ["#cba6f7", "#89b4fa", "#a6e3a1", "#f38ba8", "#fab387", "#f9e2af", "#94e2d5", "#89dceb", "#66dbb2", "#ffb4ab"]
                                    delegate: Rectangle {
                                        width: 44; height: 44; radius: 22; color: modelData; border.width: 2; border.color: cAccent === modelData ? "white" : "transparent"
                                        MouseArea { anchors.fill: parent; onClicked: if (typeof ThemeService !== "undefined") ThemeService.accent = parent.color }
                                    }
                                }
                            }
                        }
                    }

                    // --- TOOLS (2) ---
                    SettingsPage {
                        title: "System Toolbox"
                        ColumnLayout {
                            width: parent.width; spacing: 25

                            Text { text: "SPECIAL MODES"; color: cDim; font.bold: true; font.pixelSize: 9; font.letterSpacing: 1 }
                            RowLayout {
                                spacing: 15; Layout.fillWidth: true
                                ToolBtn { label: "Retro Mode"; icon: "󰄭"; btnColor: "#fab387"; onClicked: if (typeof ScriptService !== "undefined") ScriptService.toggleRetro() }
                                ToolBtn { label: "Focus Mode"; icon: "󰈉"; btnColor: "#89b4fa"; onClicked: if (typeof ScriptService !== "undefined") ScriptService.toggleFocus() }
                            }

                            Text { text: "UTILITY TOOLS"; color: cDim; font.bold: true; font.pixelSize: 9; font.letterSpacing: 1 }
                            GridLayout {
                                columns: 2; columnSpacing: 15; rowSpacing: 15; Layout.fillWidth: true
                                ToolBtn { label: "Wallpaper Picker"; icon: "󰸉"; btnColor: cAccent; onClicked: if (typeof ScriptService !== "undefined") ScriptService.openWallpaperPicker() }
                                ToolBtn { label: "Airplane Mode"; icon: "󰀝"; btnColor: "#f38ba8"; onClicked: if (typeof ScriptService !== "undefined") ScriptService.toggleAirplaneMode() }
                                ToolBtn { label: "Restart Waybar"; icon: "󰑓"; btnColor: "#a6e3a1"; onClicked: if (typeof ScriptService !== "undefined") ScriptService.restartWaybar() }
                                ToolBtn { label: "Emoji Picker"; icon: "󰞅"; btnColor: "#f9e2af"; onClicked: if (typeof ScriptService !== "undefined") ScriptService.openEmojiPicker() }
                            }

                            Text { text: "PERIPHERALS"; color: cDim; font.bold: true; font.pixelSize: 9; font.letterSpacing: 1 }
                            RowLayout {
                                spacing: 15; Layout.fillWidth: true
                                ToolBtn { label: "LED Lights On"; icon: "󰃠"; btnColor: "#94e2d5"; onClicked: if (typeof ScriptService !== "undefined") ScriptService.controlLights("start") }
                                ToolBtn { label: "LED Lights Off"; icon: "󰃟"; btnColor: "#6c7086"; onClicked: if (typeof ScriptService !== "undefined") ScriptService.controlLights("stop") }
                            }
                        }
                    }

                    // --- ABOUT ME (3) ---
                    SettingsPage {
                        title: "Personal Profile"
                        ColumnLayout {
                            width: parent.width; spacing: 25
                            RowLayout {
                                spacing: 20
                                Rectangle { width: 80; height: 80; radius: 40; color: cSurface; clip: true
                                    Image { source: (typeof ConfigService !== "undefined") ? ConfigService.profileIcon : ""; anchors.fill: parent; fillMode: Image.PreserveAspectCrop
                                        Text { anchors.centerIn: parent; visible: parent.status !== Image.Ready; text: "Z"; color: cAccent; font.pixelSize: 32; font.bold: true }
                                    }
                                }
                                ColumnLayout { spacing: 2
                                    Text { text: typeof ConfigService !== "undefined" ? ConfigService.userAlias : "Zoro"; color: cText; font.bold: true; font.pixelSize: 18 }
                                    Text { text: "Desktop Architect"; color: cAccent; font.pixelSize: 11 }
                                }
                            }
                            ColumnLayout {
                                spacing: 8; Layout.fillWidth: true
                                Text { text: "PROFILE IMAGE"; color: cDim; font.bold: true; font.pixelSize: 9 }
                                RowLayout {
                                    spacing: 10; Layout.fillWidth: true
                                    TextField { id: pathDisplay; Layout.fillWidth: true; Layout.preferredHeight: 40; readOnly: true; text: typeof ConfigService !== "undefined" ? ConfigService.profileIcon.replace("file://", "") : ""; color: cText; font.pixelSize: 11; background: Rectangle { color: cSurface; radius: 10; opacity: 0.5 } }
                                    Rectangle { Layout.preferredWidth: 100; Layout.preferredHeight: 40; radius: 10; color: selH.hovered ? cAccent : cSurface
                                        Text { anchors.centerIn: parent; text: "Select"; color: selH.hovered ? "black" : cText; font.bold: true; font.pixelSize: 11 }
                                        MouseArea { anchors.fill: parent; onClicked: fpProc.running = true } HoverHandler { id: selH }
                                    }
                                }
                                Process { id: fpProc; command: ["zenity", "--file-selection"]; stdout: StdioCollector { onStreamFinished: { if (text) { var p = text.trim(); if (p && typeof ConfigService !== "undefined") ConfigService.profileIcon = "file://" + p } } } }
                            }
                            ColumnLayout {
                                spacing: 8; Layout.fillWidth: true
                                Text { text: "ALIAS NAME"; color: cDim; font.bold: true; font.pixelSize: 9 }
                                TextField { Layout.fillWidth: true; Layout.preferredHeight: 40; text: typeof ConfigService !== "undefined" ? ConfigService.userAlias : "Zoro"; color: cText; font.pixelSize: 13; background: Rectangle { color: cSurface; radius: 10; border.width: parent.activeFocus ? 1 : 0; border.color: cAccent }
                                    onTextEdited: if (typeof ConfigService !== "undefined") ConfigService.userAlias = text
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
