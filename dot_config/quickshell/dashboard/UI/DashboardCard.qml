import QtQuick
import QtQuick.Effects
import "../Services"

Rectangle {
    // We need to access ThemeService here or pass colors as properties.
    // Using global properties from the root might be tricky if extracted.
    // So we will use ThemeService directly.
    
    color: ThemeService.surface
    radius: 24
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.08)
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowOpacity: 0.15
        shadowBlur: 0.5
        shadowVerticalOffset: 4
    }
}
