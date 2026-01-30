pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    property string wallhavenApiKey: Quickshell.env("WALLHAVEN_API_KEY") || ""
    
    // Track last two wallpapers for deletion logic
    property string lastWallpaperPath: ""
    property string prevWallpaperPath: ""
}