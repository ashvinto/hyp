import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import "../Services"

ColumnLayout {
    id: root
    property int index: 0
    property string icon: ""
    property string label: ""
    property color btnColor: ThemeService.accent
    property var action: null
    property bool active: false
    property var closeAction: null
    
    spacing: 15

    // Entry animation
    opacity: active ? 1.0 : 0
    scale: active ? 1.0 : 0.5
    
    Behavior on opacity { 
        SequentialAnimation {
            PauseAnimation { duration: 150 + (root.index * 50) }
            NumberAnimation { duration: 400 }
        }
    }
    Behavior on scale { 
        SequentialAnimation {
            PauseAnimation { duration: 150 + (root.index * 50) }
            NumberAnimation { duration: 500; easing.type: Easing.OutBack }
        }
    }

    Rectangle {
        id: btnIconBg
        width: 145; height: 115; radius: 28
        color: hover.hovered ? Qt.rgba(btnColor.r, btnColor.g, btnColor.b, 0.15) : ThemeService.surface
        border.color: hover.hovered ? btnColor : Qt.rgba(ThemeService.surface_variant.r, ThemeService.surface_variant.g, ThemeService.surface_variant.b, 0.3)
        border.width: hover.hovered ? 2 : 1
        
        Behavior on color { ColorAnimation { duration: 250 } }
        Behavior on border.color { ColorAnimation { duration: 250 } }

        Text { 
            anchors.centerIn: parent
            text: root.icon
            color: hover.hovered ? root.btnColor : ThemeService.text
            font.pixelSize: 42
            font.family: "Symbols Nerd Font"
            
            scale: hover.hovered ? 1.1 : 1.0
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            Behavior on color { ColorAnimation { duration: 250 } }
        }
        
        MouseArea { 
            anchors.fill: parent
            onClicked: { 
                if (root.action) root.action(); 
                if (root.closeAction) root.closeAction();
            }
        }
        HoverHandler { id: hover }
        
        transform: Translate {
            y: hover.hovered ? -5 : 0
            Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }
    }
    
    Text { 
        text: root.label
        color: hover.hovered ? root.btnColor : ThemeService.text
        font.pixelSize: 14; font.bold: true
        Layout.alignment: Qt.AlignHCenter
        opacity: hover.hovered ? 1 : 0.8
        
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Behavior on color { ColorAnimation { duration: 200 } }
    }
}
