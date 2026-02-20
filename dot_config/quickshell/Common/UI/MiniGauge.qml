import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell
import "../Services"

Item {
    id: root
    property string label: ""
    property real value: 0
    property string icon: ""
    property color pillColor: ThemeService.accent
    property int size: 85
    property int strokeWidth: 10 // Slightly thicker
    
    implicitWidth: size
    implicitHeight: size + (label !== "" ? 20 : 0)

    // Micro-hover scale
    scale: hoverArea.containsMouse ? 1.015 : 1.0
    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

    MouseArea { id: hoverArea; anchors.fill: parent; hoverEnabled: true }

    ColumnLayout {
        anchors.fill: parent
        spacing: 4 // Tighter spacing

        Item {
            Layout.preferredWidth: root.size
            Layout.preferredHeight: root.size
            Layout.alignment: Qt.AlignHCenter

            // Soft Inner Glow
            Shape {
                anchors.fill: parent
                opacity: 0.15
                visible: root.value > 0
                layer.enabled: true
                layer.effect: MultiEffect { blurEnabled: true; blur: 0.3 }
                
                ShapePath { 
                    strokeColor: root.pillColor; strokeWidth: root.strokeWidth + 1; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                    PathAngleArc { 
                        centerX: root.size/2; centerY: root.size/2; 
                        radiusX: root.size/2 - root.strokeWidth/2; radiusY: root.size/2 - root.strokeWidth/2; 
                        startAngle: -90; sweepAngle: (Math.min(root.value, 100)/100)*360 
                    } 
                }
            }

            // Main Track & Progress
            Shape {
                anchors.fill: parent
                layer.enabled: true
                layer.samples: 4
                
                // Track - Very subtle
                ShapePath { 
                    strokeColor: Qt.rgba(ThemeService.text.r, ThemeService.text.g, ThemeService.text.b, 0.05)
                    strokeWidth: root.strokeWidth
                    fillColor: "transparent"
                    PathAngleArc { 
                        centerX: root.size/2; centerY: root.size/2; 
                        radiusX: root.size/2 - root.strokeWidth/2; radiusY: root.size/2 - root.strokeWidth/2; 
                        startAngle: -90; sweepAngle: 360 
                    } 
                }
                
                // Progress
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
                        
                        Behavior on sweepAngle { NumberAnimation { duration: 800; easing.type: Easing.OutQuart } }
                    } 
                }
            }

            // Center Content
            Text { 
                anchors.centerIn: parent
                text: root.icon !== "" ? root.icon : (Math.round(root.value) + "%")
                color: ThemeService.text
                font.pixelSize: root.icon !== "" ? root.size * 0.38 : root.size * 0.22
                font.bold: true 
                font.family: root.icon !== "" ? "Symbols Nerd Font" : "JetBrains Mono"
                opacity: 0.85
            }
        }

        Text { 
            text: root.label
            color: ThemeService.text_dim
            font.pixelSize: 9
            font.bold: true
            font.letterSpacing: 1
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            opacity: 0.6
            visible: label !== ""
        }
    }
}
