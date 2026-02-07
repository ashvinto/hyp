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

    // --- Colors from ThemeService ---
    readonly property color cBg: ThemeService.backgroundDark
    readonly property color cSurface: ThemeService.surface
    readonly property color cAccent: ThemeService.accent
    readonly property color cText: ThemeService.text
    readonly property color cDim: ThemeService.text_dim

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
                        text: "v1.0.4 - Zoro"
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
                            text: stack.currentIndex === 0 ? "Visuals" : stack.currentIndex === 1 ? "Display" : stack.currentIndex === 2 ? "System" : "Theme"
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
                    
                    // --- VISUALS ---
                    SettingsPage {
                        title: "Appearance & Shell"
                        ColumnLayout {
                            spacing: 25
                            Layout.fillWidth: true
                            SettingSwitch { 
                                label: "Zen Mode"
                                desc: "Disable all animations and effects"
                                icon: "󰚀"
                                active: ConfigService.zenMode
                                onClicked: ConfigService.toggleZen() 
                            }
                            SettingSwitch { 
                                label: "Show Taskbar"
                                desc: "Keep the dock visible on edges"
                                icon: "󰮇"
                                active: ConfigService.showTaskbar
                                onClicked: ConfigService.showTaskbar = !ConfigService.showTaskbar 
                            }
                            SettingSlider { 
                                label: "Glass Opacity"
                                icon: "󰃟"
                                value: ConfigService.glassOpacity
                                onMoved: (v) => ConfigService.glassOpacity = v 
                            }
                            SettingSlider { 
                                label: "Dock Magnification"
                                icon: "󰍉"
                                value: (ConfigService.dockScale - 1) / 0.5
                                onMoved: (v) => ConfigService.dockScale = 1 + (v * 0.5) 
                            }
                        }
                    }

                    // --- DISPLAY ---
                    SettingsPage {
                        title: "Monitors & Effects"
                        ColumnLayout {
                            spacing: 25
                            Layout.fillWidth: true
                            SettingSlider { 
                                label: "Night Light (Warmth)"
                                icon: "󰖔"
                                value: (ConfigService.nightLightWarmth - 1000) / 5500
                                onMoved: (v) => ConfigService.setNightLight(1000 + (v * 5500)) 
                            }
                            SettingSlider { 
                                label: "Hardware Brightness"
                                icon: "󰃞"
                                value: ConfigService.softwareDim
                                onMoved: (v) => ConfigService.setDimming(v) 
                            }
                        }
                    }

                    // --- SYSTEM ---
                    SettingsPage { 
                        title: "Performance & Setup"
                        Text { 
                            text: "No system settings available yet."
                            color: cDim
                            font.italic: true 
                        } 
                    }
                    
                    // --- THEME ---
                    SettingsPage {
                        title: "Color Customization"
                        GridLayout {
                            columns: 4
                            columnSpacing: 20
                            rowSpacing: 20
                            Repeater {
                                model: ["#cba6f7", "#89b4fa", "#a6e3a1", "#f38ba8", "#fab387", "#f9e2af", "#94e2d5", "#89dceb"]
                                delegate: Rectangle {
                                    width: 60
                                    height: 60
                                    radius: 30
                                    color: modelData
                                    border.width: 3
                                    border.color: cAccent === modelData ? "white" : "transparent"
                                    MouseArea { 
                                        anchors.fill: parent
                                        onClicked: ThemeService.accent = parent.color 
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

    component SettingSwitch: RowLayout {
        property string label: ""
        property string desc: ""
        property string icon: ""
        property bool active: false
        signal clicked()
        
        spacing: 20
        Layout.fillWidth: true
        
        Rectangle { 
            width: 54
            height: 54
            radius: 16
            color: cSurface
            Text { 
                anchors.centerIn: parent
                text: icon
                color: cAccent
                font.pixelSize: 24
                font.family: "Symbols Nerd Font" 
            } 
        }
        
        ColumnLayout { 
            spacing: 2
            Layout.fillWidth: true
            Text { 
                text: label
                color: cText
                font.bold: true
                font.pixelSize: 16 
            }
            Text { 
                text: desc
                color: cDim
                font.pixelSize: 12 
            } 
        }
        
        Rectangle {
            width: 54
            height: 28
            radius: 14
            color: active ? cAccent : Qt.rgba(1,1,1,0.1)
            Rectangle { 
                x: active ? 28 : 3
                anchors.verticalCenter: parent.verticalCenter
                width: 22
                height: 22
                radius: 11
                color: "white"
                Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } } 
            }
            MouseArea { 
                anchors.fill: parent
                onClicked: parent.parent.clicked() 
            }
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
                text: Math.round(sliderComp.value * 100) + "%"
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