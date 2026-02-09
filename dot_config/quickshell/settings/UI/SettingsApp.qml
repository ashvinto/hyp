import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../Services"

PanelWindow {
    id: root
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "settings"

    // --- Colors from ThemeService (Safe Access) ---
    readonly property color cBg: (typeof ThemeService !== "undefined" && ThemeService.backgroundDark) ? ThemeService.backgroundDark : "#11111b"
    readonly property color cSurface: (typeof ThemeService !== "undefined" && ThemeService.surface) ? ThemeService.surface : "#1e1e2e"
    readonly property color cAccent: (typeof ThemeService !== "undefined" && ThemeService.accent) ? ThemeService.accent : "#cba6f7"
    readonly property color cText: (typeof ThemeService !== "undefined" && ThemeService.text) ? ThemeService.text : "#cdd6f4"
    readonly property color cDim: (typeof ThemeService !== "undefined" && ThemeService.text_dim) ? ThemeService.text_dim : "#6c7086"

    property bool active: false
    Component.onCompleted: active = true

    function close() { active = false; exitTimer.start() }
    Timer { id: exitTimer; interval: 300; onTriggered: Qt.quit() }

    MouseArea { anchors.fill: parent; z: -1; onClicked: root.close() }

    Rectangle {
        id: container
        anchors.centerIn: parent
        width: 1000
        height: 680
        radius: 32
        clip: true
        
        color: Qt.rgba(cBg.r, cBg.g, cBg.b, 0.95)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.1)

        layer.enabled: true
        layer.effect: MultiEffect { 
            shadowEnabled: true
            shadowBlur: 0.8
            shadowOpacity: 0.5
            shadowVerticalOffset: 12 
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
                Layout.preferredWidth: 240
                Layout.fillHeight: true
                color: Qt.rgba(0, 0, 0, 0.2)
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 30
                    spacing: 15
                    
                    Text { 
                        text: "PREFERENCES"
                        color: cAccent
                        font.bold: true
                        font.pixelSize: 11
                        font.letterSpacing: 2 
                    }
                    Item { Layout.preferredHeight: 10 }
                    
                    SidebarItem { 
                        icon: "󰃟"
                        label: "Visuals"
                        active: stack.currentIndex === 0
                        onClicked: stack.currentIndex = 0 
                    }
                    SidebarItem { 
                        icon: "󰖔"
                        label: "Display"
                        active: stack.currentIndex === 1
                        onClicked: stack.currentIndex = 1 
                    }
                    SidebarItem { 
                        icon: ""
                        label: "System"
                        active: stack.currentIndex === 2
                        onClicked: stack.currentIndex = 2 
                    }
                    SidebarItem { 
                        icon: "󰏘"
                        label: "Theme"
                        active: stack.currentIndex === 3
                        onClicked: stack.currentIndex = 3 
                    }
                    
                    Item { Layout.fillHeight: true }
                    Text { 
                        text: "v1.0.8 - Zoro"
                        color: cDim
                        font.pixelSize: 10
                        Layout.alignment: Qt.AlignHCenter 
                    }
                }
            }

            // --- Main Content ---
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0
                
                // Header
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    color: "transparent"
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 40
                        anchors.rightMargin: 40
                        Text { 
                            text: {
                                switch(stack.currentIndex) {
                                    case 0: return "Visuals"
                                    case 1: return "Display"
                                    case 2: return "System"
                                    case 3: return "Theme"
                                    default: return ""
                                }
                            }
                            color: cText
                            font.bold: true
                            font.pixelSize: 28 
                        }
                        Item { Layout.fillWidth: true }
                        IconButton { 
                            icon: "󰅖"
                            onClicked: root.close() 
                        }
                    }
                }

                StackLayout {
                    id: stack
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    // --- VISUALS (0) ---
                    SettingsPage {
                        title: "Appearance & Shell"
                        ColumnLayout {
                            spacing: 25
                            Layout.fillWidth: true
                            SettingSwitch { 
                                label: "Zen Mode"
                                desc: "Disable all animations and effects"
                                icon: "󰚀"
                                active: typeof ConfigService !== "undefined" ? ConfigService.zenMode : false
                                onClicked: if (typeof ConfigService !== "undefined") ConfigService.toggleZen() 
                            }
                            SettingSwitch { 
                                label: "Show Taskbar"
                                desc: "Keep the dock visible on edges"
                                icon: "󰮇"
                                active: typeof ConfigService !== "undefined" ? ConfigService.showTaskbar : true
                                onClicked: if (typeof ConfigService !== "undefined") ConfigService.showTaskbar = !ConfigService.showTaskbar 
                            }
                            SettingSlider { 
                                label: "Glass Opacity"
                                icon: "󰃟"
                                value: typeof ConfigService !== "undefined" ? ConfigService.glassOpacity : 0.85
                                onMoved: (v) => { if (typeof ConfigService !== "undefined") ConfigService.glassOpacity = v }
                            }
                            SettingSlider { 
                                label: "Dock Magnification"
                                icon: "󰍉"
                                value: typeof ConfigService !== "undefined" ? (ConfigService.dockScale - 1) / 0.5 : 0.6
                                onMoved: (v) => { if (typeof ConfigService !== "undefined") ConfigService.dockScale = 1 + (v * 0.5) }
                            }
                        }
                    }

                    // --- DISPLAY (1) ---
                    SettingsPage {
                        title: "Monitors & Effects"
                        ColumnLayout {
                            spacing: 25
                            Layout.fillWidth: true
                            SettingSlider { 
                                label: "Night Light (Warmth)"
                                icon: "󰖔"
                                value: typeof ConfigService !== "undefined" ? (ConfigService.nightLightWarmth - 1000) / 5500 : 1
                                onMoved: (v) => { if (typeof ConfigService !== "undefined") ConfigService.setNightLight(1000 + (v * 5500)) }
                            }
                            SettingSlider { 
                                label: "Hardware Brightness"
                                icon: "󰃞"
                                value: typeof ConfigService !== "undefined" ? ConfigService.softwareDim : 1
                                onMoved: (v) => { if (typeof ConfigService !== "undefined") ConfigService.setDimming(v) }
                            }
                        }
                    }

                    // --- SYSTEM (2) ---
                    SettingsPage { 
                        title: "Hyprland & Quickshell Controls"
                        ColumnLayout {
                            spacing: 25
                            Layout.fillWidth: true
                            SettingSwitch { 
                                label: "Hardware Blur"
                                desc: "Enable/Disable window blur effects"
                                icon: "󰃟"
                                active: (typeof ConfigService !== "undefined" && ConfigService.hyprBlur !== undefined) ? ConfigService.hyprBlur : true
                                onClicked: if (typeof ConfigService !== "undefined") ConfigService.hyprBlur = !ConfigService.hyprBlur 
                            }
                            SettingSlider { 
                                label: "Window Rounding"
                                icon: "󰃠"
                                value: typeof ConfigService !== "undefined" ? ConfigService.hyprRounding / 30 : 0.4
                                onMoved: (v) => { if (typeof ConfigService !== "undefined") ConfigService.hyprRounding = Math.round(v * 30) }
                            }
                            SettingSlider { 
                                label: "Inner Gaps"
                                icon: "󰖲"
                                value: typeof ConfigService !== "undefined" ? ConfigService.hyprGapsIn / 20 : 0.25
                                onMoved: (v) => { if (typeof ConfigService !== "undefined") ConfigService.hyprGapsIn = Math.round(v * 20) }
                            }
                            SettingSlider { 
                                label: "Outer Gaps"
                                icon: "󰖳"
                                value: typeof ConfigService !== "undefined" ? ConfigService.hyprGapsOut / 40 : 0.25
                                onMoved: (v) => { if (typeof ConfigService !== "undefined") ConfigService.hyprGapsOut = Math.round(v * 40) }
                            }
                        }
                    }
                    
                    // --- THEME (3) ---
                    SettingsPage {
                        title: "Color Customization"
                        GridLayout {
                            columns: 4
                            columnSpacing: 20
                            rowSpacing: 20
                            Repeater {
                                model: ["#cba6f7", "#89b4fa", "#a6e3a1", "#f38ba8", "#fab387", "#f9e2af", "#94e2d5", "#89dceb", "#66dbb2", "#ffb4ab", "#84f8cd", "#f5c2e7"]
                                delegate: Rectangle {
                                    width: 60
                                    height: 60
                                    radius: 30
                                    color: modelData
                                    border.width: 3
                                    border.color: cAccent === modelData ? "white" : "transparent"
                                    MouseArea { 
                                        anchors.fill: parent
                                        onClicked: if (typeof ThemeService !== "undefined") ThemeService.accent = parent.color
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // --- Components ---
    
    component SettingsPage: ScrollView {
        id: pageRoot
        property string title: ""
        default property alias content: mainCol.data
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentWidth: -1
        clip: true
        ColumnLayout {
            id: mainCol
            anchors.fill: parent
            anchors.margins: 40
            spacing: 30
            Text { 
                text: pageRoot.title
                color: cAccent
                font.bold: true
                font.pixelSize: 14
                font.letterSpacing: 1 
            }
        }
    }

    component SidebarItem: Rectangle {
        property string icon: ""
        property string label: ""
        property bool active: false
        signal clicked()
        
        Layout.fillWidth: true
        height: 50
        radius: 12
        color: active ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.12) : "transparent"
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            spacing: 15
            Text { 
                text: icon
                color: active ? cAccent : cText
                font.pixelSize: 20
                font.family: "Symbols Nerd Font" 
            }
            Text { 
                text: label
                color: active ? cText : cDim
                font.bold: active
                font.pixelSize: 14 
            }
        }
        MouseArea { 
            anchors.fill: parent
            onClicked: parent.clicked()
            hoverEnabled: true 
        }
    }

    component SettingSwitch: Item {
        id: switchRoot
        property string label: ""
        property string desc: ""
        property string icon: ""
        property bool active: false
        signal clicked()
        
        Layout.fillWidth: true
        height: 60

        RowLayout {
            anchors.fill: parent
            spacing: 20
            
            Rectangle { 
                width: 54
                height: 54
                radius: 16
                color: cSurface
                Text { 
                    anchors.centerIn: parent
                    text: switchRoot.icon
                    color: cAccent
                    font.pixelSize: 24
                    font.family: "Symbols Nerd Font" 
                } 
            }
            
            ColumnLayout { 
                spacing: 2
                Layout.fillWidth: true
                Text { 
                    text: switchRoot.label
                    color: cText
                    font.bold: true
                    font.pixelSize: 16 
                }
                Text { 
                    text: switchRoot.desc
                    color: cDim
                    font.pixelSize: 12 
                } 
            }
            
            Rectangle {
                width: 54
                height: 28
                radius: 14
                color: switchRoot.active ? cAccent : Qt.rgba(1,1,1,0.1)
                Rectangle { 
                    x: switchRoot.active ? 28 : 3
                    anchors.verticalCenter: parent.verticalCenter
                    width: 22
                    height: 22
                    radius: 11
                    color: "white"
                    Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } } 
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: switchRoot.clicked()
        }
    }

    component SettingSlider: ColumnLayout {
        id: sliderComp
        property string label: ""
        property string icon: ""
        property real value: 0
        signal moved(real v)
        
        spacing: 15
        Layout.fillWidth: true
        
        RowLayout {
            spacing: 15
            Text { 
                text: sliderComp.icon
                color: cAccent
                font.pixelSize: 20
                font.family: "Symbols Nerd Font" 
            }
            Text { 
                text: sliderComp.label
                color: cText
                font.bold: true
                font.pixelSize: 15
                Layout.fillWidth: true 
            }
            Text { 
                text: {
                    if (label.includes("Rounding")) return Math.round(sliderComp.value * 30)
                    if (label.includes("Inner")) return Math.round(sliderComp.value * 20)
                    if (label.includes("Outer")) return Math.round(sliderComp.value * 40)
                    return Math.round(sliderComp.value * 100) + "%"
                }
                color: cAccent
                font.bold: true
                font.pixelSize: 12 
            }
        }
        
        Slider {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            from: 0
            to: 1
            value: sliderComp.value
            onMoved: sliderComp.moved(value)
            
            background: Rectangle { 
                y: (parent.height - height) / 2
                height: 8
                radius: 4
                color: Qt.rgba(1,1,1,0.08)
                width: parent.width
                Rectangle { 
                    width: parent.parent.visualPosition * parent.width
                    height: parent.height
                    color: cAccent
                    radius: 4 
                } 
            }
            handle: Rectangle { 
                x: parent.visualPosition * (parent.width - width)
                y: (parent.height - height) / 2
                width: 24
                height: 24
                radius: 12
                color: "white"
                border.width: 5
                border.color: cAccent 
            }
        }
    }

    component IconButton: Rectangle {
        property string icon: ""
        signal clicked()
        
        width: 40
        height: 40
        radius: 20
        color: hover.hovered ? Qt.rgba(1,1,1,0.1) : "transparent"
        
        Text { 
            anchors.centerIn: parent
            text: icon
            color: cText
            font.pixelSize: 20
            font.family: "Symbols Nerd Font" 
        }
        MouseArea { 
            anchors.fill: parent
            onClicked: parent.clicked() 
        }
        HoverHandler { id: hover }
    }
}
