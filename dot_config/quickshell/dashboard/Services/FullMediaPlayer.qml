pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../Services"

Rectangle {
    id: root
    color: "transparent"
    implicitHeight: mainCol.implicitHeight

    property var player: PlayerService.activePlayer
    property real currentPos: 0
    property real currentLen: 1
    property bool userSeeking: false

    readonly property color cAccent: Config.cAccent || "#89b4fa"
    readonly property color cText: "white"
    readonly property color cDim: Qt.rgba(1, 1, 1, 0.6)
    readonly property color cSurface: Qt.rgba(1, 1, 1, 0.1)

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
    Timer { interval: 500; running: true; repeat: true; onTriggered: forceSync() }

    ColumnLayout {
        id: mainCol
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10 // Reduced spacing

        // 1. ALBUM ART (Slightly smaller)
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 140; height: 140; radius: 15
            color: cSurface
            clip: true
            
            Image {
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
            }
            
            Text {
                anchors.centerIn: parent
                text: "󰝚"
                color: cDim; font.pixelSize: 42; font.family: "Symbols Nerd Font"
                visible: !root.player?.trackArtUrl
            }
        }

        // 2. TRACK INFO
        ColumnLayout {
            Layout.fillWidth: true; spacing: 1
            Text { 
                Layout.fillWidth: true; text: (root.player?.trackTitle ?? "") || "No Media"; 
                color: cText; font.bold: true; font.pixelSize: 14; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight 
            }
            Text { 
                Layout.fillWidth: true; text: (root.player?.trackArtist ?? "") || "Waiting..."; 
                color: cAccent; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight 
            }
        }

        // 3. BONGO CAT (Smaller)
        AnimatedImage {
            id: bongoCat
            Layout.alignment: Qt.AlignHCenter
            width: 60; height: 60
            source: "../assets/bongocat.gif"
            fillMode: Image.PreserveAspectFit
            playing: root.player && root.player.playbackState === MprisPlaybackState.Playing
            onPlayingChanged: if (!playing) currentFrame = 0
        }

        // 4. PROGRESS BAR
        ColumnLayout {
            Layout.fillWidth: true; spacing: 2
            
            Rectangle {
                Layout.fillWidth: true; height: 4; radius: 2; color: cSurface
                Rectangle {
                    width: parent.width * Math.min(1, Math.max(0, root.currentPos / root.currentLen))
                    height: parent.height; radius: parent.radius; color: cAccent
                }
                MouseArea {
                    anchors.fill: parent; anchors.margins: -10
                    onPressed: { root.userSeeking = true; handleSeek(mouse.x, width) }
                    onPositionChanged: if (pressed) handleSeek(mouse.x, width)
                    onReleased: { if (root.player) root.player.position = root.currentPos; root.userSeeking = false }
                    function handleSeek(x, w) { root.currentPos = Math.min(1, Math.max(0, x / w)) * root.currentLen }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Text { text: root.formatTime(root.currentPos); color: cDim; font.pixelSize: 8 }
                Item { Layout.fillWidth: true }
                Text { text: root.formatTime(root.currentLen); color: cDim; font.pixelSize: 8 }
            }
        }

        // 5. CONTROLS
        RowLayout {
            Layout.alignment: Qt.AlignHCenter; spacing: 20
            Text { text: "󰒮"; color: cText; font.pixelSize: 18; font.family: "Symbols Nerd Font"; MouseArea { anchors.fill: parent; onClicked: if(root.player) root.player.previous() } }
            
            Rectangle {
                width: 40; height: 40; radius: 20; color: cAccent
                Text { 
                    anchors.centerIn: parent
                    text: (root.player && root.player.playbackState === MprisPlaybackState.Playing) ? "󰏤" : "󰐊"
                    color: "black"; font.pixelSize: 18; font.family: "Symbols Nerd Font"
                }
                MouseArea { anchors.fill: parent; onClicked: { if(!root.player) return; if(root.player.playbackState === MprisPlaybackState.Playing) root.player.pause(); else root.player.play() } }
            }
            
            Text { text: "󰒭"; color: cText; font.pixelSize: 18; font.family: "Symbols Nerd Font"; MouseArea { anchors.fill: parent; onClicked: if(root.player) root.player.next() } }
        }
    }
}
