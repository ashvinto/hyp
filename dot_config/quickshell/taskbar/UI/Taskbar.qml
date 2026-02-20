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
    implicitHeight: 120
    color: "transparent"

    visible: (typeof Local.ConfigService !== "undefined") ? Local.ConfigService.showTaskbar : true
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "taskbar"
    WlrLayershell.exclusiveZone: -1
    mask: Region { item: dockContainer }

    property int hoveredIdx: -1
    readonly property int baseIconSize: 52
    readonly property int iconSpacing: 12

    function getHashColor(str) {
        let hash = 0;
        let s = String(str);
        for (let i = 0; i < s.length; i++)
            hash = s.charCodeAt(i) + ((hash << 5) - hash);
        return Qt.hsla(Math.abs(hash % 360) / 360, 0.6, 0.45, 0.8);
    }

    Component.onCompleted: Local.WorkspaceService.refresh()
    Timer { interval: 500; running: true; repeat: true; onTriggered: Local.WorkspaceService.refresh() }

    Item {
        id: dockContainer
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
        width: contentRow.width + 40
        height: baseIconSize + 16

        Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            radius: 20
            color: Qt.rgba(0.05, 0.05, 0.08, 0.85)
            border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.1)
            layer.enabled: true
            layer.effect: MultiEffect { blurEnabled: true; blur: 0.3 }
        }

        Row {
            id: contentRow
            anchors.centerIn: parent
            spacing: iconSpacing

            Repeater {
                model: Local.WorkspaceService.taskList

                delegate: Item {
                    id: taskWrapper
                    width: baseIconSize * magFactor
                    height: baseIconSize

                    readonly property bool isWorkspaceActive: modelData.wsId === Local.WorkspaceService.activeId
                    readonly property bool isHovered: root.hoveredIdx === index
                    
                    readonly property real magFactor: {
                        if (root.hoveredIdx === -1) return 1.0
                        var d = Math.abs(index - root.hoveredIdx)
                        if (d === 0) return 1.5
                        if (d === 1) return 1.25
                        return 1.0
                    }

                    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                    Item {
                        id: iconVisual
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 2
                        width: baseIconSize * taskWrapper.magFactor
                        height: width
                        
                        // --- 1. ICON OR INITIALS ---
                        Rectangle {
                            id: iconBg
                            anchors.fill: parent
                            radius: width * 0.25
                            color: modelData.isEmpty ? "transparent" : "#1e1e2e"
                            border.width: modelData.isEmpty ? 1.5 : 0
                            border.color: isWorkspaceActive ? "white" : Qt.rgba(1,1,1,0.2)
                            visible: !img.visible

                            // Avoid conditional gradient assignment
                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                visible: !modelData.isEmpty
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: getHashColor(modelData.icon) }
                                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.4) }
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.isEmpty ? String(modelData.wsId) : (modelData.icon ? modelData.icon.substring(0, 1).toUpperCase() : "?")
                                color: "white"
                                font.pixelSize: parent.width * 0.5
                                font.bold: true
                            }
                        }

                        Image {
                            id: img
                            anchors.fill: parent
                            anchors.margins: parent.width * 0.1
                            fillMode: Image.PreserveAspectFit
                            source: (modelData.isEmpty || !modelData.icon) ? "" : "file:///usr/share/icons/Tela-dark/scalable/apps/" + modelData.icon + ".svg"
                            visible: status === Image.Ready
                            asynchronous: true
                        }

                        // --- 2. WORKSPACE NUMBER OVERLAY ---
                        Rectangle {
                            width: parent.width * 0.35
                            height: width
                            radius: width/2
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.topMargin: -width * 0.2
                            anchors.rightMargin: -width * 0.2
                            color: isWorkspaceActive ? "white" : "#313244"
                            border.width: 1
                            border.color: Qt.rgba(0,0,0,0.2)
                            visible: !modelData.isEmpty

                            Text {
                                anchors.centerIn: parent
                                text: modelData.wsId
                                color: isWorkspaceActive ? "black" : "white"
                                font.pixelSize: parent.width * 0.7
                                font.bold: true
                            }
                        }

                        // --- 3. ACTIVE INDICATOR (Bottom Dot) ---
                        Rectangle {
                            width: 6; height: 6; radius: 3
                            anchors.bottom: parent.bottom; anchors.bottomMargin: -10
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: "white"
                            visible: isWorkspaceActive
                            opacity: isWorkspaceActive ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true
                        onEntered: root.hoveredIdx = index
                        onExited: root.hoveredIdx = -1
                        onClicked: Local.WorkspaceService.goTo(modelData.wsId)
                    }
                }
            }
        }
    }
}
