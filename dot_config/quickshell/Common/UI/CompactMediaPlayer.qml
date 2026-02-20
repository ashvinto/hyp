pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "."
import "../Services"

Item {
    id: root
    implicitHeight: content.implicitHeight
    Layout.fillWidth: true
    Layout.fillHeight: true

    property var player: PlayerService.activePlayer
    property real currentPos: 0
    property real currentLen: 1
    property bool userSeeking: false

    readonly property var localVibes: [
        "file:///home/zoro/.config/quickshell/lockscreen/assets/bongocat.gif",
        "file:///home/zoro/.config/quickshell/lockscreen/assets/kurukuru.gif",
        "file:///home/zoro/.config/quickshell/lockscreen/assets/dino.png"
    ]
    
    property string currentVibe: localVibes[0]
    property bool isWebVibe: false

    function formatTime(s) {
        if (!s || s <= 0 || isNaN(s)) return "0:00"
        const m = Math.floor(s / 60); const sec = Math.floor(s % 60)
        return m + ":" + (sec < 10 ? "0" : "") + sec
    }

    function forceSync() {
        if (!player) { currentPos = 0; currentLen = 1; return }
        let meta = player.metadata
        let rawLen = meta["mpris:length"] || 0
        if (rawLen > 1000000) currentLen = rawLen / 1000000
        else currentLen = rawLen > 0 ? rawLen : (player.length || 1)
        if (!userSeeking) {
            currentPos = player.position
            if (currentPos > currentLen + 1) currentPos = 0
        }
    }

    // Debounce vibe fetching
    Timer {
        id: vibeDebounce
        interval: 1500; running: false; repeat: false
        onTriggered: fetchWebVibe()
    }

    function fetchWebVibe() {
        let useMeme = Math.random() > 0.5
        let url = useMeme ? "https://meme-api.com/gimme" : "https://api.thecatapi.com/v1/images/search?mime_types=gif"
        
        var xhr = new XMLHttpRequest()
        xhr.open("GET", url)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var json = JSON.parse(xhr.responseText)
                        var newUrl = ""
                        if (useMeme) {
                            newUrl = json.url
                            // Filter out known broken Reddit static links if they aren't working
                            if (newUrl.indexOf("preview.redd.it") !== -1) {
                                fallbackToLocal(); return
                            }
                        } else {
                            newUrl = json[0].url
                        }
                        
                        if (newUrl && (newUrl.indexOf(".gif") !== -1 || newUrl.indexOf(".png") !== -1 || newUrl.indexOf(".jpg") !== -1 || newUrl.indexOf(".webp") !== -1)) {
                            currentVibe = newUrl
                            isWebVibe = true
                        } else {
                            fallbackToLocal()
                        }
                    } catch(e) { 
                        fallbackToLocal()
                    }
                } else {
                    fallbackToLocal()
                }
            }
        }
        xhr.send()
    }

    function fallbackToLocal() {
        currentVibe = localVibes[Math.floor(Math.random() * localVibes.length)]
        isWebVibe = false
    }

    onPlayerChanged: { forceSync(); vibeDebounce.restart() }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: forceSync() }
    Timer { interval: 300000; running: player && player.playbackState === MprisPlaybackState.Playing; repeat: true; onTriggered: fetchWebVibe() }

    Component.onCompleted: { 
        forceSync()
        // Ensure immediate load on startup
        fetchWebVibe()
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        spacing: 6

        // 1. TOP VIBE
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 90; Layout.preferredHeight: 90
            
            AnimatedImage {
                id: vibeImage
                anchors.fill: parent
                source: root.currentVibe
                fillMode: Image.PreserveAspectFit
                playing: root.player && root.player.playbackState === MprisPlaybackState.Playing
                // Critical: handle loading errors immediately
                onStatusChanged: {
                    if (status === AnimatedImage.Error) {
                        console.log("[MediaPlayer] Vibe load error, falling back...")
                        fallbackToLocal()
                    }
                }
            }

            MouseArea {
                anchors.fill: parent; hoverEnabled: true; id: vibeMouse
                onClicked: fetchWebVibe()
                Rectangle {
                    anchors.bottom: parent.bottom; anchors.right: parent.right
                    width: 20; height: 20; radius: 10; color: Qt.rgba(0,0,0,0.5)
                    opacity: vibeMouse.containsMouse ? 1.0 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    Text { anchors.centerIn: parent; text: "󰑐"; color: "white"; font.pixelSize: 10; font.family: "Symbols Nerd Font" }
                }
            }
        }

        // 2. TRACK INFO
        ColumnLayout {
            spacing: 0; Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: (root.player?.trackTitle ?? "") || "No Media Playing"
                color: ThemeService.text; font.pixelSize: 15; font.bold: true
                elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
            }
            Text {
                Layout.fillWidth: true
                text: (root.player?.trackArtist ?? "") || "..."
                color: ThemeService.accent; font.pixelSize: 11
                elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter; opacity: 0.8
            }
        }

        // 3. PROGRESS BAR
        ColumnLayout {
            spacing: 2; Layout.fillWidth: true
            
            Rectangle {
                id: barContainer
                Layout.fillWidth: true; implicitHeight: 4; radius: 2
                color: Qt.rgba(ThemeService.text.r, ThemeService.text.g, ThemeService.text.b, 0.1)
                
                Rectangle {
                    id: barFill
                    width: parent.width * Math.min(1, Math.max(0, root.currentPos / root.currentLen))
                    height: parent.height; radius: parent.radius
                    color: root.userSeeking ? ThemeService.accent : ThemeService.text
                }

                Rectangle {
                    id: handle
                    x: (parent.width * Math.min(1, Math.max(0, root.currentPos / root.currentLen))) - width/2
                    anchors.verticalCenter: parent.verticalCenter
                    width: barMouseArea.containsMouse || root.userSeeking ? 10 : 0
                    height: width; radius: width / 2; color: ThemeService.text
                    Behavior on width { NumberAnimation { duration: 150 } }
                }

                MouseArea {
                    id: barMouseArea; anchors.fill: parent; anchors.margins: -10; hoverEnabled: true
                    onPressed: root.userSeeking = true
                    onPositionChanged: (mouse) => { if (pressed) root.currentPos = Math.min(1, Math.max(0, mouse.x / width)) * root.currentLen }
                    onReleased: (mouse) => {
                        if (!root.player) return
                        let p = Math.min(1, Math.max(0, mouse.x / width)) * root.currentLen
                        root.player.position = p; root.currentPos = p; root.userSeeking = false
                    }
                }
            }
            
            RowLayout {
                Layout.fillWidth: true
                Text { text: root.formatTime(root.currentPos); color: ThemeService.text_dim; font.pixelSize: 8; opacity: 0.6 }
                Item { Layout.fillWidth: true }
                Text { text: root.formatTime(root.currentLen); color: ThemeService.text_dim; font.pixelSize: 8; opacity: 0.6 }
            }
        }

        // 4. CONTROLS
        RowLayout {
            spacing: 24; Layout.alignment: Qt.AlignHCenter
            
            ClickableIcon {
                iconString: "󰒮"; fontSize: 22
                iconColor: (root.player && root.player.canGoPrevious) ? ThemeService.text : ThemeService.text_dim
                clickAction: () => { if (root.player) root.player.previous() }
            }

            Rectangle {
                width: 44; height: 44; radius: 22
                color: playMouse.containsMouse ? Qt.rgba(ThemeService.text.r, ThemeService.text.g, ThemeService.text.b, 0.15) : Qt.rgba(ThemeService.text.r, ThemeService.text.g, ThemeService.text.b, 0.1)
                border.color: Qt.rgba(1,1,1,0.05); border.width: 1
                
                Text {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: (root.player && root.player.playbackState === MprisPlaybackState.Playing) ? 0 : 2
                    text: (root.player && root.player.playbackState === MprisPlaybackState.Playing) ? "󰏤" : "󰐊"
                    color: ThemeService.text; font.pixelSize: 24; font.family: "Symbols Nerd Font"
                }

                MouseArea {
                    id: playMouse; anchors.fill: parent; hoverEnabled: true
                    onClicked: {
                        if (root.player) {
                            if (root.player.playbackState === MprisPlaybackState.Playing) root.player.pause()
                            else root.player.play()
                        }
                    }
                    onPressed: parent.scale = 0.92; onReleased: parent.scale = 1.0
                }
                Behavior on scale { NumberAnimation { duration: 100 } }
            }

            ClickableIcon {
                iconString: "󰒭"; fontSize: 22
                iconColor: (root.player && root.player.canGoNext) ? ThemeService.text : ThemeService.text_dim
                clickAction: () => { if (root.player) root.player.next() }
            }
        }

        // 5. Spacer to push everything up
        Item { Layout.fillHeight: true }
    }
}
