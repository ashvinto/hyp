pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property color textColor: "#cdd6f4"
    readonly property color mediaPlayerButtonInactive: "#45475a"
    readonly property real mediaPlayerButtonSize: 20
    readonly property real mediaPlayerButtonSpacing: 12
    readonly property string textFontFamily: "JetBrains Mono"
    readonly property real fontSize: 12
    readonly property real mediaPlayerSmallFontSize: 9
    readonly property real mediaPlayerBarSize: 4
    readonly property color mediaPlayerBarUnfilled: "#313244"
    readonly property color mediaPlayerBarFilled: "#cba6f7"
    readonly property color mediaPlayerSelectorBorder: "#313244"
    readonly property color mediaPlayerSelectorBackground: "#1e1e2e"
    readonly property color mediaPlayerSelectorSelected: "#45475a"
    readonly property real smallMediaPlayerSwitcherSpacing: 10
}