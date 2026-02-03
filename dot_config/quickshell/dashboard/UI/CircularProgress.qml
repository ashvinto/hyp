import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import "../Services"

ColumnLayout {
    property real value: 0
    property string label: ""
    property color color: ThemeService.accent
    property color cText: ThemeService.text
    property color cDim: ThemeService.text_dim
    property color cSurface: ThemeService.surface_variant
    property int size: 60

    spacing: 4
    
    Item {
        width: size; height: size
        Layout.alignment: Qt.AlignHCenter

        Item {
            anchors.fill: parent
            // Background Track
            Rectangle {
                anchors.fill: parent; radius: size/2
                color: "transparent"; border.width: Math.max(2, size/12); border.color: cSurface
            }
            
            // Progress Arc
            Shape {
                anchors.fill: parent
                layer.enabled: true; layer.samples: 4
                ShapePath {
                    strokeColor: color; strokeWidth: Math.max(2, size/12); fillColor: "transparent"; capStyle: ShapePath.RoundCap
                    PathAngleArc { 
                        centerX: size/2; centerY: size/2; 
                        radiusX: size/2 - Math.max(1, size/24); radiusY: size/2 - Math.max(1, size/24); 
                        startAngle: -90; sweepAngle: (Math.min(value, 100) / 100) * 360 
                    }
                }
            }
            
            Text {
                anchors.centerIn: parent
                text: Math.round(value) + "%"
                color: cText; font.bold: true; font.pixelSize: Math.max(8, size/5); font.family: "JetBrains Mono"
            }
        }
    }
    Text { 
        Layout.alignment: Qt.AlignHCenter
        text: label; color: cDim; font.bold: true; font.pixelSize: Math.max(7, size/6)
    }
}