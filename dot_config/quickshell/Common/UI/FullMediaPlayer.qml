pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "."

Rectangle {
    id: root
    color: "transparent"
    implicitHeight: content.height

    property var player: PlayerService.activePlayer
    property real currentPos: 0
    property real currentLen: 1
    property bool userSeeking: false

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

    onPlayerChanged: forceSync()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: forceSync() }

    Connections {
        target: player
        ignoreUnknownSignals: true
        function onTrackTitleChanged() { forceSync() }
        function onMetadataChanged() { forceSync() }
    }

    RowLayout {
        id: content
        anchors.centerIn: root
        spacing: 20
        width: root.width - 24

        // Album Art with Glow/Shadow effect
        Item {
            width: 140; height: 140
            Layout.alignment: Qt.AlignVCenter
            
            Rectangle {
                anchors.fill: parent
                radius: 20
                color: Qt.darker(Config.mediaPlayerSelectorBackground, 1.5)
                opacity: 0.5
                anchors.topMargin: 4
            }

            Rectangle {
                id: artContainer
                anchors.fill: parent
                radius: 20
                color: Config.mediaPlayerSelectorBackground
                clip: true
                
                Image { 
                    anchors.fill: parent
                    source: root.player?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }
                
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.color: Qt.rgba(1, 1, 1, 0.1)
                    border.width: 1
                    radius: 20
                }

                Text { 
                    anchors.centerIn: parent
                    text: ""
                    font.pixelSize: 48
                    color: Config.mediaPlayerButtonInactive
                    visible: !root.player?.trackArtUrl
                }
            }

            MouseArea { 
                anchors.fill: parent
                hoverEnabled: true
                onClicked: if (root.player && root.player.canRaise) root.player.raise()
                onPressed: artContainer.scale = 0.95
                onReleased: artContainer.scale = 1.0
            }
            
            Behavior on scale { NumberAnimation { duration: 100 } }
        }

        ColumnLayout {
            spacing: 12
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            // Track Info
            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                
                Text {
                    Layout.fillWidth: true
                    text: (root.player?.trackTitle ?? "") || "No Media Playing"
                    color: "white"
                    font.pixelSize: 18
                    font.bold: true
                    elide: Text.ElideRight
                    font.family: Config.textFontFamily
                }
                
                Text {
                    Layout.fillWidth: true
                    text: (root.player?.trackArtist ?? "") || "Unknown Artist"
                    color: Config.cAccent
                    font.pixelSize: 13
                    elide: Text.ElideRight
                    font.family: Config.textFontFamily
                }
            }

            // Progress Bar
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                
                Rectangle {
                    id: barContainer
                    Layout.fillWidth: true
                    implicitHeight: 6
                    radius: 3
                    color: Qt.rgba(Config.mediaPlayerBarUnfilled.r, Config.mediaPlayerBarUnfilled.g, Config.mediaPlayerBarUnfilled.b, 0.4)
                    
                    Rectangle {
                        id: barFill
                        width: parent.width * Math.min(1, Math.max(0, root.currentPos / root.currentLen))
                        height: parent.height
                        radius: parent.radius
                        color: root.userSeeking ? Config.cAccent : Config.mediaPlayerBarFilled
                        
                        // Subtle highlight
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: "white"
                            opacity: 0.1
                            anchors.bottomMargin: parent.height / 2
                        }
                    }
                    
                    Rectangle {
                        id: handle
                        x: (parent.width * Math.min(1, Math.max(0, root.currentPos / root.currentLen))) - width/2
                        anchors.verticalCenter: parent.verticalCenter
                        width: barMouseArea.containsMouse || root.userSeeking ? 14 : 0
                        height: width
                        radius: width / 2
                        color: "white"
                        border.color: Config.mediaPlayerBarFilled
                        border.width: 2
                        
                        Behavior on width { NumberAnimation { duration: 150 } }
                    }

                    MouseArea {
                        id: barMouseArea
                        anchors.fill: parent
                        anchors.margins: -10
                        hoverEnabled: true
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
                    Text { 
                        text: root.formatTime(root.currentPos)
                        color: Qt.rgba(Config.textColor.r, Config.textColor.g, Config.textColor.b, 0.7)
                        font.pixelSize: 10
                        font.family: "JetBrains Mono"
                    }
                    Item { Layout.fillWidth: true }
                    Text { 
                        text: root.formatTime(root.currentLen)
                        color: Qt.rgba(Config.textColor.r, Config.textColor.g, Config.textColor.b, 0.7)
                        font.pixelSize: 10
                        font.family: "JetBrains Mono"
                    }
                }
            }

            // Controls
            RowLayout {
                spacing: 24
                Layout.alignment: Qt.AlignLeft
                
                ClickableIcon {
                    iconString: "󰒮"
                    fontSize: 24
                    iconColor: (root.player && root.player.canGoPrevious) ? "white" : Config.mediaPlayerButtonInactive
                    clickAction: () => { if (root.player) root.player.previous() }
                }

                Rectangle {
                    width: 44; height: 44; radius: 22
                    color: playMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.1)
                    
                    Text {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: (root.player && root.player.playbackState === MprisPlaybackState.Playing) ? 0 : 2
                        text: (root.player && root.player.playbackState === MprisPlaybackState.Playing) ? "󰏤" : "󰐊"
                        color: "white"
                        font.pixelSize: 28
                        font.family: "JetBrainsMono Nerd Font"
                    }

                    MouseArea {
                        id: playMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (root.player) {
                                if (root.player.playbackState === MprisPlaybackState.Playing) root.player.pause()
                                else root.player.play()
                            }
                        }
                    }
                }

                ClickableIcon {
                    iconString: "󰒭"
                    fontSize: 24
                    iconColor: (root.player && root.player.canGoNext) ? "white" : Config.mediaPlayerButtonInactive
                    clickAction: () => { if (root.player) root.player.next() }
                }
            }
                }
            }
        }
        