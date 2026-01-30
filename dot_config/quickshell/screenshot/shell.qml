import QtQuick
import Quickshell
import "./UI"
import "./Services"

ShellRoot {
    id: root
    
    // Load Panel or Overlay based on service state
    
    Loader {
        active: ScreenshotService.activeMode === "panel"
        sourceComponent: ScreenshotPanel {}
    }

    Loader {
        active: ScreenshotService.activeMode === "overlay"
        sourceComponent: FreezeOverlay {}
    }
}