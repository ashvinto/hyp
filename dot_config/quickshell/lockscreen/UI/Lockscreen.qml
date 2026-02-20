import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import "."
import "../Services"

PanelWindow {
    id: root
    
    anchors.top: true; anchors.bottom: true; anchors.left: true; anchors.right: true
    color: "black"
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "lockscreen"

    // --- Services ---
    LockContext {
        id: lockContext
        onUnlocked: Qt.quit()
        onFailed: { passwordInput.text = ''; shakeAnim.start() }
    }

    property var currentTime: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.currentTime = new Date() }

    FileView { id: wallpaperCache; path: "/home/zoro/.cache/current_wallpaper" }
    readonly property string wallpaperPath: {
        var t = ""
        try { t = wallpaperCache.text() } catch(e) {}
        return (t && t !== "") ? ("file://" + t.trim()) : ""
    }

    // ================= LAYER 1: BACKGROUND =================
    Item {
        id: backgroundLayer
        anchors.fill: parent
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: ThemeService.backgroundDark || "#000" }
                GradientStop { position: 1.0; color: ThemeService.background || "#111" }
            }
        }
        Image { 
            id: bgImage; anchors.fill: parent; source: root.wallpaperPath
            fillMode: Image.PreserveAspectCrop; visible: status === Image.Ready; asynchronous: true
        }
    }

    // ================= LAYER 2: BLUR =================
    ShaderEffectSource {
        id: blurSource; anchors.fill: parent; sourceItem: backgroundLayer; recursive: false; hideSource: true
    }
    MultiEffect {
        anchors.fill: parent; source: blurSource; blurEnabled: true; blur: 0.8; brightness: -0.2
    }

    // ================= LAYER 2.5: PARTICLES =================
    Item {
        id: particleLayer
        anchors.fill: parent
        z: 0.5

        Repeater {
            model: 40
            delegate: Rectangle {
                id: dot
                width: Math.random() * 6 + 2; height: width; radius: width/2
                color: ThemeService.accent
                
                property real startX: Math.random() * parent.width
                property real startY: Math.random() * parent.height
                property int duration: Math.random() * 15000 + 15000

                x: startX; y: startY
                opacity: Math.random() * 0.6 + 0.3

                layer.enabled: true
                layer.effect: MultiEffect { blurEnabled: true; blur: 0.4; brightness: 0.2 }

                SequentialAnimation on x {
                    loops: Animation.Infinite
                    NumberAnimation { from: startX; to: startX + (Math.random() * 400 - 200); duration: dot.duration; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: startX; duration: dot.duration; easing.type: Easing.InOutQuad }
                }

                SequentialAnimation on y {
                    loops: Animation.Infinite
                    NumberAnimation { from: startY; to: startY + (Math.random() * 400 - 200); duration: dot.duration; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: startY; duration: dot.duration; easing.type: Easing.InOutQuad }
                }

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.2; to: 0.8; duration: dot.duration / 2; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 0.8; to: 0.2; duration: dot.duration / 2; easing.type: Easing.InOutQuad }
                }
            }
        }
    }

    // ================= LAYER 3: UI =================
    Item {
        id: uiRoot
        anchors.fill: parent

        // Main Glass Shadow (Static again)
        Rectangle {
            anchors.centerIn: glassPlate
            width: glassPlate.width; height: glassPlate.height; radius: 48
            color: "black"
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true; shadowOpacity: 0.7; shadowBlur: 1.0; shadowVerticalOffset: 40
            }
        }

        // --- Main Glass Plate ---
        Rectangle {
            id: glassPlate
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.94, 1400)
            height: Math.min(parent.height * 0.90, 900)
            radius: 48
            color: Qt.rgba(0.08, 0.08, 0.1, 0.82) 
            clip: true

            // Frosted Glass Noise Shader
            ShaderEffect {
                anchors.fill: parent
                opacity: 0.025
                readonly property string grainShader: "
                    varying highp vec2 qt_TexCoord0;
                    uniform lowp float qt_Opacity;
                    lowp float rand(vec2 co) {
                        return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
                    }
                    void main() {
                        gl_FragColor = vec4(vec3(rand(qt_TexCoord0)), 1.0) * qt_Opacity;
                    }
                "
            }

            // Inner Shadow/Highlight
            Rectangle {
                anchors.fill: parent; radius: 48; color: "transparent"
                border.color: Qt.rgba(1, 1, 1, 0.12); border.width: 1.5; anchors.margins: 1
            }

            // Additional "Sheen" Layer
            Rectangle {
                anchors.fill: parent; radius: 48
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.05) }
                    GradientStop { position: 0.4; color: "transparent" }
                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.1) }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 60 
                spacing: 40

                // 1. LEFT COLUMN
                ColumnLayout {
                    Layout.preferredWidth: parent.width * 0.28
                    Layout.fillHeight: true
                    spacing: 30 

                    LockCard {
                        Layout.preferredHeight: 180
                        content: ColumnLayout {
                            spacing: 12
                            Text { text: "WEATHER"; color: ThemeService.accent; font.bold: true; font.pixelSize: 10; font.letterSpacing: 2 }
                            RowLayout {
                                spacing: 18
                                Text { text: WeatherService.icon; color: ThemeService.text; font.pixelSize: 52; font.family: "Symbols Nerd Font" }
                                ColumnLayout {
                                    spacing: 0
                                    Text { text: WeatherService.temp; color: ThemeService.text; font.bold: true; font.pixelSize: 32 }
                                    Text { text: WeatherService.description; color: ThemeService.text_dim; font.pixelSize: 14 }
                                }
                            }
                            Text { text: "Humidity " + WeatherService.humidity + "%"; color: ThemeService.text_dim; font.pixelSize: 11 }
                        }
                    }

                    LockCard {
                        Layout.preferredHeight: 260
                        content: ColumnLayout {
                            spacing: 15
                            Text { text: "SYSTEM INFOS"; color: ThemeService.accent; font.bold: true; font.pixelSize: 10; font.letterSpacing: 2 }
                            RowLayout {
                                Layout.fillWidth: true; spacing: 20
                                Text { text: "󰣇"; color: "#1793d1"; font.pixelSize: 84; font.family: "Symbols Nerd Font" }
                                ColumnLayout {
                                    spacing: 6
                                    Text { text: "Arch Linux"; color: ThemeService.text; font.bold: true; font.pixelSize: 18 }
                                    Text { text: "User: " + SystemService.user; color: ThemeService.text; font.pixelSize: 13 }
                                    Text { text: "Uptime: " + (SystemService.uptime || "0m"); color: ThemeService.text; font.pixelSize: 13 }
                                }
                            }
                            RowLayout {
                                spacing: 10; Layout.topMargin: 10
                                Repeater {
                                    model: ["#f38ba8", "#fab387", "#f9e2af", "#a6e3a1", "#89b4fa", "#cba6f7"]
                                    delegate: Rectangle { width: 34; height: 12; radius: 6; color: modelData; border.color: Qt.rgba(1,1,1,0.1); border.width: 1 }
                                }
                            }
                        }
                    }

                    LockCard {
                        Layout.fillHeight: true
                        content: ColumnLayout {
                            spacing: 12
                            Text { text: "NOW PLAYING"; color: ThemeService.accent; font.bold: true; font.pixelSize: 10; font.letterSpacing: 2 }
                            CompactMediaPlayer { Layout.fillWidth: true; Layout.fillHeight: true }
                        }
                    }
                }

                // 2. CENTER COLUMN
                ColumnLayout {
                    id: centerCol
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 50 

                    Item { Layout.fillHeight: true }

                    ColumnLayout {
                        id: clockContainer
                        Layout.alignment: Qt.AlignHCenter; spacing: -10 
                        
                        property real tiltX: 0
                        property real tiltY: 0

                        MouseArea {
                            anchors.fill: parent; hoverEnabled: true
                            onMouseXChanged: clockContainer.tiltY = (mouseX - width/2) / (width/2) * 15
                            onMouseYChanged: clockContainer.tiltX = (height/2 - mouseY) / (height/2) * 15
                            onExited: { clockContainer.tiltX = 0; clockContainer.tiltY = 0 }
                        }

                        transform: [
                            Rotation { axis.x: 1; axis.y: 0; axis.z: 0; origin.x: clockContainer.width/2; origin.y: clockContainer.height/2; angle: clockContainer.tiltX },
                            Rotation { axis.x: 0; axis.y: 1; axis.z: 0; origin.x: clockContainer.width/2; origin.y: clockContainer.height/2; angle: clockContainer.tiltY }
                        ]
                        Behavior on transform { PropertyAnimation { duration: 200 } }

                        Text { 
                            id: clockText
                            text: Qt.formatTime(root.currentTime, "hh:mm")
                            color: ThemeService.text; font.pixelSize: 180; font.bold: true; font.family: "JetBrains Mono"
                            font.letterSpacing: -10; Layout.alignment: Qt.AlignHCenter
                            transformOrigin: Item.Center
                            
                            layer.enabled: true
                            layer.effect: MultiEffect { 
                                shadowEnabled: true; shadowOpacity: 0.5; shadowBlur: 0.4
                                shadowHorizontalOffset: clockContainer.tiltY * -2
                                shadowVerticalOffset: 5 + (clockContainer.tiltX * -2)
                            }
                        }
                        Text { 
                            text: Qt.formatDate(root.currentTime, "dddd, dd MMMM yyyy").toUpperCase()
                            color: ThemeService.accent; font.pixelSize: 16; font.letterSpacing: 6
                            font.weight: Font.DemiBold; Layout.alignment: Qt.AlignHCenter 
                            opacity: 0.8
                        }
                    }

                    // CENTER CONTENT (Fixed visibility)
                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        width: 180; height: 180

                        Rectangle {
                            anchors.fill: profileContainer; radius: 12; color: "black"
                            layer.enabled: true
                            layer.effect: MultiEffect { shadowEnabled: true; shadowOpacity: 0.5; shadowBlur: 0.5; shadowVerticalOffset: 15 }
                        }

                        Rectangle {
                            id: profileContainer
                            anchors.fill: parent; radius: 12
                            color: Qt.rgba(0,0,0,0.4)
                            clip: true 

                            // 1. Fallback Arch Logo (Bottom layer)
                            Text {
                                anchors.centerIn: parent
                                text: "󰣇"; color: ThemeService.accent; font.pixelSize: 100
                                font.family: "Symbols Nerd Font"; opacity: 0.1
                            }

                            // 2. Animated kurukuru (Middle layer - Always present)
                            AnimatedImage {
                                id: kurukuruGif
                                anchors.fill: parent
                                source: "file:///home/zoro/.config/quickshell/lockscreen/assets/kurukuru.gif"
                                fillMode: Image.PreserveAspectCrop
                            }

                            // 3. Profile Image (Top layer - Overlays if exists)
                            Image {
                                id: profileImg
                                anchors.fill: parent
                                source: ConfigService.profileIcon
                                fillMode: Image.PreserveAspectCrop
                                visible: status === Image.Ready
                            }

                            // Inner Highlight
                            Rectangle {
                                anchors.fill: parent; radius: 12; color: "transparent"
                                border.color: Qt.rgba(1, 1, 1, 0.1); border.width: 1
                            }
                        }
                    }

                    Item {
                        id: passContainer
                        Layout.alignment: Qt.AlignHCenter; width: 380; height: 64
                        
                        property real tiltX: 0
                        property real tiltY: 0

                        MouseArea {
                            anchors.fill: parent; hoverEnabled: true
                            onMouseXChanged: passContainer.tiltY = (mouseX - width/2) / (width/2) * 10
                            onMouseYChanged: passContainer.tiltX = (height/2 - mouseY) / (height/2) * 10
                            onExited: { passContainer.tiltX = 0; passContainer.tiltY = 0 }
                        }

                        transform: [
                            Rotation { axis.x: 1; axis.y: 0; axis.z: 0; origin.x: passContainer.width/2; origin.y: passContainer.height/2; angle: passContainer.tiltX },
                            Rotation { axis.x: 0; axis.y: 1; axis.z: 0; origin.x: passContainer.width/2; origin.y: passContainer.height/2; angle: passContainer.tiltY }
                        ]
                        Behavior on transform { PropertyAnimation { duration: 200 } }

                        // 1. Outer Shadow (Elevation) - Reactive
                        Rectangle {
                            anchors.fill: parent; radius: 32; color: "black"
                            layer.enabled: true
                            layer.effect: MultiEffect { 
                                shadowEnabled: true; shadowOpacity: 0.6; shadowBlur: 0.6
                                shadowHorizontalOffset: passContainer.tiltY * -3
                                shadowVerticalOffset: 15 + (passContainer.tiltX * -3)
                            }
                        }

                        // 2. Main Frame (The "Rim")
                        Rectangle {
                            id: passFrame
                            anchors.fill: parent; radius: 32
                            color: Qt.rgba(0.15, 0.15, 0.18, 0.9)
                            border.color: Qt.rgba(1, 1, 1, 0.1); border.width: 1

                            // 3. Inner Recessed Area (The "Well")
                            Rectangle {
                                anchors.fill: parent; anchors.margins: 4; radius: 28
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.5) } // Top shadow inside
                                    GradientStop { position: 0.2; color: Qt.rgba(0, 0, 0, 0.2) }
                                    GradientStop { position: 1.0; color: Qt.rgba(0.1, 0.1, 0.1, 0.1) }
                                }
                                border.color: Qt.rgba(0, 0, 0, 0.4); border.width: 1.5
                            }

                            // 4. Accent Rim Glow
                            Rectangle {
                                anchors.fill: parent; radius: 32; color: "transparent"
                                border.color: ThemeService.accent; border.width: 1.5; opacity: 0.4
                            }

                            // 5. Top Highlight (Light Reflection)
                            Rectangle {
                                width: parent.width - 40; height: 1.5; anchors.top: parent.top; anchors.topMargin: 1
                                anchors.horizontalCenter: parent.horizontalCenter
                                radius: 1; color: Qt.rgba(1, 1, 1, 0.2)
                            }

                            SequentialAnimation {
                                id: shakeAnim
                                NumberAnimation { target: passFrame; property: "anchors.horizontalCenterOffset"; from: 0; to: 10; duration: 60 }
                                NumberAnimation { target: passFrame; property: "anchors.horizontalCenterOffset"; from: 10; to: -10; duration: 60 }
                                NumberAnimation { target: passFrame; property: "anchors.horizontalCenterOffset"; from: -10; to: 0; duration: 60 }
                            }

                            RowLayout {
                                anchors.fill: parent; anchors.margins: 6; spacing: 12
                                Item { Layout.preferredWidth: 12 }
                                Text { 
                                    text: "󰌾"; color: ThemeService.accent; font.pixelSize: 22; font.family: "Symbols Nerd Font"
                                    layer.enabled: true; layer.effect: MultiEffect { shadowEnabled: true; shadowOpacity: 0.5; shadowBlur: 0.2; shadowVerticalOffset: 2 }
                                }
                                TextField { 
                                    id: passwordInput; Layout.fillWidth: true; Layout.fillHeight: true
                                    placeholderText: "Type Password"; echoMode: TextInput.Password
                                    color: "white"; font.pixelSize: 16; background: null; focus: true
                                    placeholderTextColor: Qt.rgba(1, 1, 1, 0.3)
                                    onAccepted: { lockContext.currentText = text; lockContext.tryUnlock() }
                                }
                                Rectangle {
                                    width: 52; height: 52; radius: 26; color: ThemeService.accent
                                    layer.enabled: true; layer.effect: MultiEffect { shadowEnabled: true; shadowOpacity: 0.4; shadowBlur: 0.3; shadowVerticalOffset: 4 }
                                    Text { anchors.centerIn: parent; text: "󰁔"; color: "black"; font.bold: true; font.pixelSize: 22; font.family: "Symbols Nerd Font" }
                                    MouseArea { 
                                        anchors.fill: parent; 
                                        onClicked: { lockContext.currentText = passwordInput.text; lockContext.tryUnlock() }
                                        onPressed: parent.scale = 0.92
                                        onReleased: parent.scale = 1.0
                                    }
                                    Behavior on scale { NumberAnimation { duration: 100 } }
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }

                // 3. RIGHT COLUMN
                ColumnLayout {
                    Layout.preferredWidth: parent.width * 0.25
                    Layout.fillHeight: true
                    spacing: 30

                    LockCard {
                        Layout.preferredHeight: 220
                        content: ColumnLayout {
                            spacing: 10
                            Text { text: "INSTRUMENTS"; color: ThemeService.accent; font.bold: true; font.pixelSize: 10; font.letterSpacing: 2; Layout.alignment: Qt.AlignHCenter }
                            GridLayout {
                                columns: 2; columnSpacing: 20; rowSpacing: 20; Layout.alignment: Qt.AlignHCenter
                                MiniGauge { value: ResourceService.cpu; icon: ""; pillColor: "#f38ba8"; size: 70 }
                                MiniGauge { value: ResourceService.ram; icon: ""; pillColor: "#fab387"; size: 70 }
                                MiniGauge { value: ResourceService.gpu; icon: "󰢽"; pillColor: "#89b4fa"; size: 70 }
                                MiniGauge { value: QuickSettingsService.batteryLevel; icon: "󰁹"; pillColor: "#a6e3a1"; size: 70 }
                            }
                        }
                    }

                    LockCard {
                        Layout.fillHeight: true
                        scrollable: false
                        content: ColumnLayout {
                            spacing: 12
                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "TO-DO"; color: ThemeService.accent; font.bold: true; font.pixelSize: 10; font.letterSpacing: 2 }
                                Item { Layout.fillWidth: true }
                                Rectangle {
                                    width: 22; height: 22; radius: 11; color: ThemeService.accent
                                    Text { anchors.centerIn: parent; text: TodoService.pendingCount; color: "black"; font.bold: true; font.pixelSize: 10 }
                                }
                            }
                            TodoList { Layout.fillWidth: true; Layout.fillHeight: true }
                        }
                    }
                }
            }
        }
    }

    // --- Modular Card Component ---
    component LockCard: Item {
        id: cardRoot
        property alias content: cardLoader.sourceComponent
        property bool scrollable: false
        Layout.fillWidth: true

        property real tiltX: 0
        property real tiltY: 0

        Behavior on tiltX { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on tiltY { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

        // 3D Tilt transformation
        transform: [
            Rotation { axis.x: 1; axis.y: 0; axis.z: 0; origin.x: cardRoot.width / 2; origin.y: cardRoot.height / 2; angle: cardRoot.tiltX },
            Rotation { axis.x: 0; axis.y: 1; axis.z: 0; origin.x: cardRoot.width / 2; origin.y: cardRoot.height / 2; angle: cardRoot.tiltY }
        ]

        MouseArea {
            id: cardMouse
            anchors.fill: parent
            hoverEnabled: true
            onMouseXChanged: if (containsMouse) cardRoot.tiltY = (mouseX - width/2) / (width/2) * 8
            onMouseYChanged: if (containsMouse) cardRoot.tiltX = (height/2 - mouseY) / (height/2) * 8
            onExited: { cardRoot.tiltX = 0; cardRoot.tiltY = 0 }
        }

        Rectangle {
            anchors.fill: cardRect
            radius: 32; color: "black"
            layer.enabled: true
            layer.effect: MultiEffect {
                id: shadowEffect
                shadowEnabled: true
                shadowOpacity: cardMouse.containsMouse ? 0.6 : 0.3
                shadowBlur: cardMouse.containsMouse ? 0.8 : 0.5
                // Dynamic localized shadow
                shadowHorizontalOffset: cardRoot.tiltY * -4
                shadowVerticalOffset: (cardMouse.containsMouse ? 30 : 10) + (cardRoot.tiltX * -4)
                
                Behavior on shadowOpacity { NumberAnimation { duration: 300 } }
                Behavior on shadowBlur { NumberAnimation { duration: 300 } }
                Behavior on shadowVerticalOffset { NumberAnimation { duration: 300 } }

                // Breathing animation using 'on' syntax to avoid scoping issues
                SequentialAnimation on shadowOpacity {
                    running: !cardMouse.containsMouse; loops: Animation.Infinite
                    NumberAnimation { from: 0.25; to: 0.4; duration: 4000; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 0.4; to: 0.25; duration: 4000; easing.type: Easing.InOutQuad }
                }
            }
        }

        Rectangle {
            id: cardRect
            anchors.fill: parent
            radius: 32
            gradient: Gradient {
                GradientStop { position: 0.0; color: cardMouse.containsMouse ? Qt.rgba(0.14, 0.14, 0.20, 0.8) : Qt.rgba(0.12, 0.12, 0.18, 0.75) }
                GradientStop { position: 1.0; color: cardMouse.containsMouse ? Qt.rgba(0.10, 0.10, 0.14, 0.75) : Qt.rgba(0.08, 0.08, 0.12, 0.7) }
            }
            border.color: cardMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.2) : Qt.rgba(1, 1, 1, 0.1)
            border.width: 1; clip: true

            Behavior on border.color { ColorAnimation { duration: 300 } }

            // Inner Shadow Simulation
            Rectangle {
                anchors.fill: parent; radius: 32; color: "transparent"
                border.color: Qt.rgba(1, 1, 1, 0.05); border.width: 2; anchors.margins: 1
            }

            // Highlight Edges
            Rectangle {
                width: parent.width - 40; height: 1.5; anchors.top: parent.top; anchors.topMargin: 1
                anchors.horizontalCenter: parent.horizontalCenter
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.5; color: cardMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.3) : Qt.rgba(1, 1, 1, 0.15) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            Loader {
                id: cardLoader
                anchors.fill: parent; anchors.margins: 28 
                visible: !cardRoot.scrollable
            }

            Flickable {
                anchors.fill: parent; anchors.margins: 28; visible: cardRoot.scrollable
                clip: true
                contentWidth: width; contentHeight: cardLoaderScroll.implicitHeight
                interactive: true

                Loader { 
                    id: cardLoaderScroll
                    sourceComponent: cardRoot.content; 
                    width: parent.width 
                }

                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            }
        }
    }
}
