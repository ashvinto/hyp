import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../Services" as Local
import "../../Common/Services" as Common

PanelWindow {
    id: root
    
    anchors { bottom: true; left: true; right: true }
    implicitHeight: 160
    color: "transparent"

    // Controlled by Settings via Common Services
    // Safe access: defaulting to true if service is undefined
    visible: (typeof Common.ConfigService !== "undefined" && Common.ConfigService.showTaskbar !== undefined) ? Common.ConfigService.showTaskbar : true

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "taskbar"
    WlrLayershell.exclusiveZone: -1

    property bool active: false
    property int hoveredIdx: -1
    
    // Find the index of the active workspace in the model
    readonly property int activeIdx: {
        var ws = Local.WorkspaceService.workspaces
        for (var i = 0; i < ws.length; i++) {
            if (ws[i].id === Local.WorkspaceService.activeId) return i;
        }
        return 0;
    }

    Component.onCompleted: { 
        active = true
        Local.WorkspaceService.refresh() 
    }
    
    Timer { 
        interval: 1000 
        running: true 
        repeat: true 
        onTriggered: Local.WorkspaceService.refresh() 
    }

    // --- Colors from ThemeService (Safe Access) ---
    readonly property color cBg: (typeof Common.ThemeService !== "undefined" && Common.ThemeService.backgroundDark) ? Common.ThemeService.backgroundDark : "#11111b"
    readonly property color cAccent: (typeof Common.ThemeService !== "undefined" && Common.ThemeService.accent) ? Common.ThemeService.accent : "#cba6f7"
    readonly property color cText: (typeof Common.ThemeService !== "undefined" && Common.ThemeService.text) ? Common.ThemeService.text : "#cdd6f4"
    readonly property color cDim: (typeof Common.ThemeService !== "undefined" && Common.ThemeService.text_dim) ? Common.ThemeService.text_dim : "#6c7086"

    // --- The Apple Style Dock ---
    Rectangle {
        id: dock
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 30
        anchors.horizontalCenter: parent.horizontalCenter
        
        width: contentRow.width + 44
        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        
        height: 76
        radius: 24
        
        // Safe opacity access
        readonly property real glassOp: (typeof Common.ConfigService !== "undefined" && Common.ConfigService.glassOpacity !== undefined) ? Common.ConfigService.glassOpacity : 0.85

        // Use Theme Colors + Glass Opacity
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(cBg.r, cBg.g, cBg.b, dock.glassOp) }
            GradientStop { position: 1.0; color: Qt.rgba(cBg.r, cBg.g, cBg.b, Math.min(1.0, dock.glassOp + 0.1)) }
        }
        
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.15)

        // --- MOVING GLASS HIGHLIGHT (Hover OR Active) ---
        Rectangle {
            id: movingHighlight
            property int targetIdx: hoveredIdx !== -1 ? hoveredIdx : activeIdx
            
            x: 22 + (targetIdx * (56 + 12)) 
            width: 56
            height: 56
            radius: 14
            anchors.verticalCenter: parent.verticalCenter
            
            color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.15)
            border.width: 1; border.color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.3)
            
            Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
            
            layer.enabled: true
            layer.effect: MultiEffect { 
                shadowEnabled: true; shadowBlur: 0.5; shadowOpacity: 0.4; shadowColor: cAccent 
            }
        }

        layer.enabled: true
        layer.effect: MultiEffect { 
            shadowEnabled: true
            shadowBlur: 0.8
            shadowOpacity: 0.5
            shadowVerticalOffset: 10
        }

        // --- Ambient Glass Shimmer ---
        Rectangle {
            anchors.fill: parent; radius: parent.radius; clip: true; color: "transparent"
            Rectangle {
                id: shimmer
                width: parent.width * 0.8; height: parent.height * 4; rotation: 35; y: -parent.height * 1.5
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.06) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
                NumberAnimation on x { from: -dock.width * 2; to: dock.width * 2; duration: 6000; loops: Animation.Infinite; running: true }
            }
        }

        y: active ? parent.height - height - 30 : parent.height + 50
        Behavior on y { NumberAnimation { duration: 700; easing.type: Easing.OutBack } }

        RowLayout {
            id: contentRow; anchors.centerIn: parent; spacing: 12

            Repeater {
                model: Local.WorkspaceService.workspaces
                delegate: Item {
                    width: 56; height: 56
                    property bool isActive: modelData.id === Local.WorkspaceService.activeId
                    property var appList: modelData.apps || []
                    property int appCount: appList.length

                    // Icon Container
                    Rectangle {
                        id: iconContainer
                        anchors.centerIn: parent; width: 50; height: 50; radius: 12
                        color: "transparent"
                        
                        // --- SINGLE APP ---
                        Image {
                            id: singleIcon
                            anchors.centerIn: parent; width: 44; height: 44; fillMode: Image.PreserveAspectFit; smooth: true
                            visible: appCount === 1 && status === Image.Ready
                            source: appCount === 1 ? ("file:///usr/share/icons/Tela-dark/scalable/apps/" + appList[0] + ".svg") : ""
                            onStatusChanged: if (status === Image.Error) source = "image://theme/" + appList[0]
                        }

                        // --- FOLDER GRID ---
                        GridLayout {
                            anchors.centerIn: parent; width: 36; height: 36; columns: 2; columnSpacing: 4; rowSpacing: 4
                            visible: appCount > 1

                            Repeater {
                                model: Math.min(appCount, 4)
                                delegate: Item {
                                    Layout.preferredWidth: 16; Layout.preferredHeight: 16
                                    Image {
                                        id: miniIcon; anchors.fill: parent; fillMode: Image.PreserveAspectFit; smooth: true
                                        source: "file:///usr/share/icons/Tela-dark/scalable/apps/" + appList[index] + ".svg"
                                        onStatusChanged: if (status === Image.Error) source = "image://theme/" + appList[index]
                                    }
                                    Text {
                                        anchors.centerIn: parent; visible: miniIcon.status !== Image.Ready
                                        text: appList[index].charAt(0).toUpperCase(); color: "white"; font.pixelSize: 10; font.bold: true
                                    }
                                }
                            }
                        }

                        // --- FALLBACK TEXT ---
                        Text {
                            anchors.centerIn: parent
                            visible: appCount === 0 || (appCount === 1 && singleIcon.status !== Image.Ready)
                            text: (appCount === 1) ? appList[0].charAt(0).toUpperCase() : modelData.id
                            color: (appCount > 0) ? "white" : (isActive ? "#ffffff" : "#606060")
                            font.pixelSize: (appCount > 0) ? 24 : 18; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                        }

                        // Safe access for scale
                        readonly property real targetScale: (typeof Common.ConfigService !== "undefined" && Common.ConfigService.dockScale !== undefined) ? Common.ConfigService.dockScale : 1.3
                        scale: mouseArea.containsMouse ? targetScale : 1.0
                        Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                    }

                    // Bottom Indicator Dot
                    Rectangle {
                        anchors.bottom: parent.bottom; anchors.bottomMargin: -10
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 5; height: 5; radius: 2.5
                        color: isActive ? cAccent : "transparent"
                        opacity: isActive ? 1.0 : 0
                        Behavior on opacity { NumberAnimation { duration: 400 } }
                    }

                    MouseArea { 
                        id: mouseArea
                        anchors.fill: parent; hoverEnabled: true
                        onEntered: root.hoveredIdx = index
                        onExited: root.hoveredIdx = -1
                        onClicked: Local.WorkspaceService.goTo(modelData.id) 
                    }
                }
            }
        }
    }
}
