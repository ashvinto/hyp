pragma Singleton
import QtQuick
import Quickshell
import "."

Singleton {
    readonly property color textColor: ThemeService.text
    readonly property color mediaPlayerButtonInactive: ThemeService.text_dim
    readonly property real mediaPlayerButtonSize: 24
    readonly property real mediaPlayerButtonSpacing: 20
    readonly property string textFontFamily: "JetBrains Mono"
    readonly property real fontSize: 14
    readonly property real mediaPlayerSmallFontSize: 11
    readonly property real mediaPlayerBarSize: 4
    readonly property color mediaPlayerBarUnfilled: ThemeService.surface_variant
    readonly property color mediaPlayerBarFilled: ThemeService.accent
    readonly property color mediaPlayerSelectorBorder: ThemeService.surface_variant
    readonly property color mediaPlayerSelectorBackground: ThemeService.surface
    readonly property color mediaPlayerSelectorSelected: ThemeService.surface_variant
    readonly property real smallMediaPlayerSwitcherSpacing: 10
}
