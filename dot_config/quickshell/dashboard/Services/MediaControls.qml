import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "."

RowLayout {
    id: root
    property var player: null
    Layout.fillWidth: true
    Layout.alignment: Qt.AlignCenter
    Layout.margins: 10
    spacing: Config.mediaPlayerButtonSpacing

    ClickableIcon {
        iconString: "󰒮"
        iconColor: (root.player && root.player.canGoPrevious) ? Config.textColor : Config.mediaPlayerButtonInactive
        fontSize: Config.mediaPlayerButtonSize
        clickAction: function () {
            if (root.player) root.player.previous();
        }
    }

    ClickableIcon {
        iconString: (root.player && root.player.playbackState === MprisPlaybackState.Playing) ? "󰏤" : "󰐊"
        iconColor: (root.player && (root.player.canPlay || root.player.canPause)) ? Config.textColor : Config.mediaPlayerButtonInactive
        fontSize: Config.mediaPlayerButtonSize
        clickAction: function () {
            if (root.player) {
                if (root.player.playbackState === MprisPlaybackState.Playing)
                    root.player.pause()
                else
                    root.player.play()
            }
        }
    }

    ClickableIcon {
        iconString: "󰒭"
        iconColor: (root.player && root.player.canGoNext) ? Config.textColor : Config.mediaPlayerButtonInactive
        fontSize: Config.mediaPlayerButtonSize
        clickAction: function () {
            if (root.player) root.player.next();
        }
    }
}
