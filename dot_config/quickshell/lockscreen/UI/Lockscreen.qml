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

    readonly property color cBg: ThemeService.background
    readonly property color cCard: ThemeService.surface
    readonly property color cBorder: ThemeService.surface_variant
    readonly property color cText: ThemeService.text
    readonly property color cAccent: ThemeService.accent
    readonly property color cDim: ThemeService.text_dim

    property int unreadNotifications: 0
    Process {
        id: notifCountProc
        command: ["dunstctl", "count", "waiting"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) root.unreadNotifications = parseInt(text.trim()) || 0
            }
        }
    }
    Timer { interval: 3000; running: true; repeat: true; onTriggered: notifCountProc.running = true }

    // Lock context for authentication
    LockContext {
        id: lockContext
        onUnlocked: {
            console.log("[Lockscreen] Unlocked signal received, quitting...")
            Qt.quit()
        }
        onFailed: passwordInput.text = ''  // Clear password on failure
    }

    property var currentTime: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.currentTime = new Date() }

    property string commitQuote: ""
    property var fallbackQuotes: [
        "Fixing everything by breaking everything else.",
        "It worked on my machine.",
        "Commit early, commit often, regret always.",
        "Refactored the refactor of the refactor.",
        "I have no idea what I'm doing.",
        "Added more bugs to balance things out.",
        "Caffeine.convert(code);",
        "Trust me, I'm an engineer.",
        "One more 'final' fix.",
        "It's not a bug, it's a feature."
    ]

    function setRandomFallback() {
        var index = Math.floor(Math.random() * fallbackQuotes.length);
        root.commitQuote = fallbackQuotes[index];
    }

    Process {
        id: quoteProcess
        command: ["curl", "--connect-timeout", "3", "-s", "https://whatthecommit.com/index.txt"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim() !== "") {
                    root.commitQuote = text.trim();
                } else {
                    root.setRandomFallback();
                }
            }
        }
        onExited: (status) => {
            if (status !== 0) {
                root.setRandomFallback();
            }
        }
    }

    Timer {
        id: quoteTimer
        interval: 60000 // Refresh every minute
        running: true
        repeat: true
        onTriggered: quoteProcess.running = true
    }

    FileView {
        id: wallpaperCache
        path: "/home/zoro/.cache/current_wallpaper"
    }

    readonly property string wallpaperPath: {
        // FileView.text is a method in Quickshell
        var t = ""
        try {
            t = wallpaperCache.text()
        } catch(e) {}
        
        return (t && t !== "") ? ("file://" + t.trim()) : ""
    }

    Item {
        anchors.fill: parent
        Image { 
            id: bgImage
            anchors.fill: parent
            source: root.wallpaperPath
            fillMode: Image.PreserveAspectCrop
            visible: false
            asynchronous: true
            cache: false 
        }
        MultiEffect { 
            anchors.fill: parent
            source: bgImage
            blurEnabled: true
            blur: 0.7
            brightness: -0.4
            opacity: bgImage.status === Image.Ready ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 800 } }
        }
        Rectangle { 
            anchors.fill: parent
            color: "black"
            opacity: bgImage.status === Image.Ready ? 0.4 : 1.0
            Behavior on opacity { NumberAnimation { duration: 800 } }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        ColumnLayout {
            anchors.centerIn: parent
            width: 1100
            spacing: 20

            // Animated Asset (Kurukuru)
            AnimatedImage {
                Layout.alignment: Qt.AlignHCenter
                source: "../assets/kurukuru.gif"
                width: 150
                height: 150
                fillMode: Image.PreserveAspectFit
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 0
                Text { 
                    text: Qt.formatTime(root.currentTime, "HH:mm:ss")
                    color: cText
                    font.pixelSize: 120
                    font.bold: true
                    font.family: "JetBrains Mono"
                }
                Text { 
                    text: Qt.formatDate(root.currentTime, "dddd, MMMM d")
                    color: cAccent
                    font.pixelSize: 24
                    font.letterSpacing: 2
                    Layout.alignment: Qt.AlignHCenter 
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 400
                height: 60
                color: cCard
                radius: 30
                border.color: cAccent
                border.width: 2
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10
                    Text { text: "󰌾"; color: cAccent; font.pixelSize: 20; Layout.leftMargin: 10 }
                    TextField { 
                        id: passwordInput
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        placeholderText: "Type to unlock..."
                        echoMode: TextInput.Password
                        color: "white"
                        font.pixelSize: 18
                        background: null
                        focus: true
                        Component.onCompleted: focusTimer.start()
                        
                        onAccepted: {
                            // Use the LockContext service for authentication
                            lockContext.currentText = passwordInput.text;
                            lockContext.tryUnlock();
                        } 
                    }
                    Timer { id: focusTimer; interval: 100; onTriggered: passwordInput.forceActiveFocus() }
                }
            }

            RowLayout {
                spacing: 24
                Layout.alignment: Qt.AlignHCenter

                Rectangle {
                    width: 280; height: 220
                    color: cCard; radius: 32; border.color: cBorder
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 15
                        Rectangle { 
                            width: 80; height: 80; radius: 40; color: cAccent
                            clip: true
                            Image {
                                source: (typeof ConfigService !== "undefined") ? ConfigService.profileIcon : "file:///home/zoro/.face"
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                onStatusChanged: if (status == Image.Error) fallbackIcon.visible = true
                            }
                            Text { 
                                id: fallbackIcon
                                anchors.centerIn: parent
                                text: SystemService.user[0].toUpperCase()
                                font.bold: true
                                font.pixelSize: 32
                                color: "#000" 
                                visible: false
                            }
                        }
                        Text { 
                            text: SystemService.user
                            color: "white"
                            font.bold: true
                            font.pixelSize: 20
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text { 
                            text: "System Locked"
                            color: cDim
                            font.pixelSize: 12
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }

                Rectangle {
                    width: 400; height: 200
                    color: cCard; radius: 32; border.color: cBorder; clip: true
                    FullMediaPlayer { 
                        anchors.centerIn: parent
                        width: 360 
                    }
                }

                                                Rectangle {
                                                    width: 340; height: 220
                                                    color: cCard; radius: 32; border.color: cBorder
                                                    ColumnLayout {
                                                        anchors.fill: parent
                                                        anchors.margins: 25
                                                        spacing: 15
                                                        Text { 
                                                            text: "SYSTEM HEALTH"
                                                            color: cDim
                                                            font.bold: true
                                                            font.pixelSize: 11
                                                            font.letterSpacing: 1
                                                            Layout.alignment: Qt.AlignHCenter 
                                                        }
                                                                                RowLayout {
                                                                                    Layout.alignment: Qt.AlignHCenter
                                                                                    spacing: 10
                                                                                    MiniGauge { label: "CPU"; value: ResourceService.cpu; pillColor: ThemeService.error; size: 60; strokeWidth: 6 }
                                                                                    MiniGauge { label: "RAM"; value: ResourceService.ram; pillColor: cAccent; size: 60; strokeWidth: 6 }
                                                                                    MiniGauge { label: "GPU"; value: ResourceService.gpu; pillColor: ThemeService.primary; size: 60; strokeWidth: 6 }
                                                                                    MiniGauge { label: "BAT"; value: QuickSettingsService.batteryLevel; pillColor: QuickSettingsService.isCharging ? ThemeService.success : cAccent; size: 60; strokeWidth: 6 }
                                                                                }                                        

                                        // Spacer

                                        Item { Layout.fillHeight: true }

                        // Quick Settings
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 20
                            
                            // Night Light
                            ClickableIcon {
                                iconString: "󰖔" // Weather/Night icon
                                iconColor: "#f9e2af"
                                fontSize: 22
                                clickAction: () => {
                                    processService.run(["/home/zoro/.config/hypr/scripts/night_light.sh"])
                                }
                            }
                            
                            // Airplane Mode
                            ClickableIcon {
                                iconString: "󰀝" // Airplane icon
                                iconColor: "#89dceb"
                                fontSize: 22
                                clickAction: () => {
                                    processService.run(["/home/zoro/.config/hypr/scripts/AirplaneMode.sh"])
                                }
                            }

                            // DND / Mute
                             ClickableIcon {
                                iconString: "󰂚" // Bell icon
                                iconColor: "#f38ba8"
                                fontSize: 22
                                clickAction: () => {
                                    processService.run(["dunstctl", "set-paused", "toggle"])
                                }
                            }
                        }
                    }
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 800
                text: root.commitQuote
                color: cDim
                font.pixelSize: 18
                font.italic: true
                font.family: "JetBrains Mono"
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                opacity: text !== "" ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 500 } }
            }
        }
    }

    Component.onCompleted: quoteProcess.running = true

    // Helper for running processes since Lockscreen might not have global processService
    QtObject {
        id: processService
        function run(cmd) {
            var proc = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
            proc.command = cmd;
            proc.running = true;
        }
    }
}
