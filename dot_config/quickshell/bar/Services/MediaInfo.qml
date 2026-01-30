import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "."

ColumnLayout {
    id: root
    property var player: null
    spacing: 2

    Text {
        Layout.alignment: Qt.AlignCenter
        Layout.maximumWidth: root.width
        text: qsTr((root.player?.trackTitle ?? "") || "No Media")
        clip: true
        elide: Text.ElideRight
        font.family: Config.textFontFamily
        font.pointSize: Config.fontSize
        color: Config.textColor
    }

    Text {
        Layout.alignment: Qt.AlignCenter
        Layout.maximumWidth: root.width
        text: qsTr((root.player?.trackArtist ?? "") || "")
        clip: true
        elide: Text.ElideRight
        font.family: Config.textFontFamily
        font.pointSize: Config.mediaPlayerSmallFontSize
        color: Config.textColor
    }
}
