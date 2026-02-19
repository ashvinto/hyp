import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell
import "../Services"

ColumnLayout {
    id: root
    property string label: ""
    property real value: 0
    property color pillColor: ThemeService.accent
    property int size: 70
    property int strokeWidth: 8
    
    spacing: 10
    
    Item {
        width: root.size; height: root.size
        Layout.alignment: Qt.AlignHCenter

        // Glow Layer
        Shape {
            anchors.fill: parent
            opacity: 0.3
            visible: root.value > 0
            layer.enabled: true
            layer.effect: MultiEffect { blurEnabled: true; blur: 0.5; brightness: 0.2 }
            
            ShapePath { 
                strokeColor: root.pillColor; strokeWidth: root.strokeWidth + 2; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                PathAngleArc { 
                    centerX: root.size/2; centerY: root.size/2; 
                    radiusX: root.size/2 - root.strokeWidth/2; radiusY: root.size/2 - root.strokeWidth/2; 
                    startAngle: -90; sweepAngle: (Math.min(root.value, 100)/100)*360 
                } 
            }
        }

        // Main Shape
        Shape {
            anchors.fill: parent
            layer.enabled: true
            layer.samples: 4
            
            // Background Track
            ShapePath { 
                strokeColor: ThemeService.surface_variant
                strokeWidth: root.strokeWidth
                fillColor: "transparent"
                PathAngleArc { 
                    centerX: root.size/2; centerY: root.size/2; 
                    radiusX: root.size/2 - root.strokeWidth/2; radiusY: root.size/2 - root.strokeWidth/2; 
                    startAngle: -90; sweepAngle: 360 
                } 
            }
            
            // Progress Arc
            ShapePath { 
                strokeColor: root.pillColor
                strokeWidth: root.strokeWidth
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                
                PathAngleArc { 
                    centerX: root.size/2; centerY: root.size/2; 
                    radiusX: root.size/2 - root.strokeWidth/2; radiusY: root.size/2 - root.strokeWidth/2; 
                    startAngle: -90
                    sweepAngle: (Math.min(root.value, 100)/100)*360 
                    
                    Behavior on sweepAngle { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                } 
            }
        }

        Text { 
            anchors.centerIn: parent
            text: Math.round(root.value) + "%"
            color: ThemeService.text
            font.pixelSize: root.size * 0.22
            font.bold: true 
            font.family: "JetBrains Mono"
        }
    }

    Text { 
        text: root.label
        color: ThemeService.text_dim
        font.pixelSize: root.size * 0.16
        font.bold: true
        font.letterSpacing: 1
        Layout.alignment: Qt.AlignHCenter 
        opacity: 0.8
    }
}
