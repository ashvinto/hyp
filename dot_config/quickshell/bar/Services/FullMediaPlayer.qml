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

    ColumnLayout {
        id: content
        anchors.centerIn: root
        spacing: 8
        width: root.width

        Rectangle {
            Layout.alignment: Qt.AlignCenter
            width: 90; height: 90; radius: 12
            color: Config.mediaPlayerSelectorBackground; clip: true
            Image { anchors.fill: parent; source: root.player?.trackArtUrl ?? ""; fillMode: Image.PreserveAspectCrop; visible: status === Image.Ready }
            Text { anchors.centerIn: parent; text: ""; font.pixelSize: 32; color: Config.mediaPlayerButtonInactive; visible: !root.player?.trackArtUrl }
            MouseArea { anchors.fill: parent; onClicked: if (root.player && root.player.canRaise) root.player.raise() }
        }

        MediaInfo { Layout.alignment: Qt.AlignCenter; Layout.maximumWidth: 300; player: root.player }
        MediaControls { player: root.player; Layout.margins: 0 }

        ColumnLayout {
            Layout.alignment: Qt.AlignCenter; Layout.preferredWidth: 250; spacing: 4
            Rectangle {
                id: bar; Layout.fillWidth: true; implicitHeight: 4; radius: 2; color: Config.mediaPlayerBarUnfilled
                Rectangle {
                    width: parent.width * Math.min(1, Math.max(0, root.currentPos / root.currentLen))
                    height: parent.height; radius: parent.radius; color: root.userSeeking ? "#fcd34d" : Config.mediaPlayerBarFilled
                }
                Rectangle {
                    x: (parent.width * Math.min(1, Math.max(0, root.currentPos / root.currentLen))) - width/2
                    anchors.verticalCenter: parent.verticalCenter; width: 10; height: 10; radius: 5
                    color: root.userSeeking ? "#fcd34d" : "white"; visible: barMouseArea.containsMouse || root.userSeeking
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
                Text { text: root.formatTime(root.currentPos); color: Config.textColor; font.pixelSize: 10 }
                Item { Layout.fillWidth: true }
                Text { text: root.formatTime(root.currentLen); color: Config.textColor; font.pixelSize: 10 }
            }
        }

        ComboBox {
            id: playerSelector; Layout.alignment: Qt.AlignCenter; Layout.preferredWidth: 180; Layout.preferredHeight: 26
            model: Mpris.players.values; textRole: "identity"; currentIndex: Mpris.players.values.indexOf(root.player)
            onActivated: (index) => PlayerService.activePlayer = Mpris.players.values[index]
            background: Rectangle { color: Config.mediaPlayerSelectorBackground; border.color: Config.mediaPlayerSelectorBorder; radius: 4 }
            contentItem: Text { text: playerSelector.displayText; color: Config.textColor; font.pixelSize: 10; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight }
        }
    }
}