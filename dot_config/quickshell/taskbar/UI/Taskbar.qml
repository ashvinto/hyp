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
    implicitHeight: 140
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "taskbar"
    WlrLayershell.exclusiveZone: -1
    mask: Region { item: dockContainer }

    property int hoveredIdx: -1
    readonly property int baseIconSize: 64
    readonly property int iconSpacing: 14

    function getHashColor(str) {
        let hash = 0;
        let s = String(str);
        for (let i = 0; i < s.length; i++)
            hash = s.charCodeAt(i) + ((hash << 5) - hash);
        return Qt.hsla(Math.abs(hash % 360) / 360, 0.6, 0.4, 0.8);
    }

    Component.onCompleted: Local.WorkspaceService.refresh()
    Timer { interval: 150; running: true; repeat: true; onTriggered: Local.WorkspaceService.refresh() }

    Item {
        id: dockContainer
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        width: contentRow.width + 44
        height: baseIconSize + 20

        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            radius: 24
            color: Qt.rgba(0.06, 0.06, 0.1, 0.75)
            border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.1)
            layer.enabled: true
            layer.effect: MultiEffect { blurEnabled: true; blur: 0.4 }
        }

        Row {
            id: contentRow
            anchors.centerIn: parent
            spacing: iconSpacing

            Repeater {
                model: Local.WorkspaceService.workspaces

                delegate: Item {
                    id: iconWrapper
                    width: baseIconSize * magFactor
                    height: baseIconSize

                    readonly property bool isActive: modelData.id === Local.WorkspaceService.activeId
                    readonly property bool isHovered: root.hoveredIdx === index
                    readonly property var appList: modelData.apps ? modelData.apps : []

                    readonly property real magFactor: {
                        if (root.hoveredIdx === -1) return 1.0
                        var d = Math.abs(index - root.hoveredIdx)
                        if (d === 0) return 1.7
                        if (d === 1) return 1.35
                        return 1.0
                    }

                    Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                    Item {
                        id: iconVisual
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 2
                        width: baseIconSize * iconWrapper.magFactor
                        height: width
                        clip: true
                        readonly property real sharedRadius: width * 0.23

                        // --- 1. BIG INITIALS ---
                        Rectangle {
                            id: bigInitials
                            anchors.fill: parent
                            radius: iconVisual.sharedRadius
                            visible: iconWrapper.appList.length <= 1
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: getHashColor(iconWrapper.appList.length > 0 ? iconWrapper.appList[0] : modelData.id) }
                                GradientStop { position: 1.0; color: Qt.darker(getHashColor(iconWrapper.appList.length > 0 ? iconWrapper.appList[0] : modelData.id), 1.6) }
                            }
                            Text {
                                anchors.centerIn: parent
                                text: iconWrapper.appList.length > 0
                                      ? String(iconWrapper.appList[0]).substring(0, 2).toUpperCase()
                                      : String(modelData.id)
                                color: "white"; font.pixelSize: parent.width * 0.4; font.weight: Font.Bold
                            }
                        }

                        // --- 2. SINGLE ICON VIEW ---
                        Image {
                            id: mainImg
                            anchors.fill: parent
                            anchors.margins: parent.width * 0.05
                            visible: iconWrapper.appList.length === 1
                            fillMode: Image.PreserveAspectFit
                            source: visible ? "file:///usr/share/icons/Tela-dark/scalable/apps/" + iconWrapper.appList[0] + ".svg" : ""
                            asynchronous: true
                            onStatusChanged: if (status === Image.Ready) bigInitials.visible = false
                        }

                        // --- 3. FOLDER VIEW WITH EXPAND ANIMATION ---
                        Rectangle {
                            id: folderView
                            anchors.fill: parent
                            radius: iconVisual.sharedRadius
                            visible: iconWrapper.appList.length > 1
                            color: isHovered ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.08)

                            Behavior on color { ColorAnimation { duration: 150 } }

                            GridLayout {
                                id: folderGrid
                                anchors.fill: parent

                                // EXPAND LOGIC: Margins get smaller on hover to let icons "grow"
                                anchors.margins: isHovered ? parent.width * 0.08 : parent.width * 0.18
                                columns: 2; rows: 2

                                // Spacing increases slightly on hover for clarity
                                columnSpacing: isHovered ? 6 : 4
                                rowSpacing: isHovered ? 6 : 4

                                Behavior on anchors.margins { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                Behavior on columnSpacing { NumberAnimation { duration: 200 } }
                                Behavior on rowSpacing { NumberAnimation { duration: 200 } }

                                Repeater {
                                    model: Math.min(iconWrapper.appList.length, 4)
                                    delegate: Item {
                                        Layout.fillWidth: true; Layout.fillHeight: true

                                        Image {
                                            id: miniImg
                                            anchors.fill: parent
                                            fillMode: Image.PreserveAspectFit
                                            source: "file:///usr/share/icons/Tela-dark/scalable/apps/" + iconWrapper.appList[index] + ".svg"
                                            visible: status === Image.Ready
                                            asynchronous: true

                                            // Subtle scale pop on each individual icon
                                            scale: isHovered ? 1.05 : 1.0
                                            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: parent.width * 0.2
                                            visible: !miniImg.visible
                                            gradient: Gradient {
                                                GradientStop { position: 0.0; color: getHashColor(iconWrapper.appList[index]) }
                                                GradientStop { position: 1.0; color: Qt.darker(getHashColor(iconWrapper.appList[index]), 1.6) }
                                            }
                                            Text {
                                                anchors.centerIn: parent
                                                text: String(iconWrapper.appList[index]).substring(0, 1).toUpperCase()
                                                color: "white"; font.pixelSize: parent.width * 0.6; font.bold: true
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // --- 4. GLASS OVERLAY ---
                        Rectangle {
                            width: parent.width - 2; height: parent.height - 2
                            anchors.centerIn: parent
                            radius: iconVisual.sharedRadius
                            opacity: (isActive || isHovered) ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 150 } }

                            gradient: Gradient {
                                orientation: Gradient.Vertical
                                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.35) }
                                GradientStop { position: 0.45; color: Qt.rgba(1, 1, 1, 0.1) }
                                GradientStop { position: 1.0; color: "transparent" }
                            }

                            border.width: isActive ? 1.6 : (isHovered ? 1.1 : 0)
                            border.color: isActive ? Qt.rgba(1, 1, 1, 0.5) : Qt.rgba(1, 1, 1, 0.25)
                            layer.enabled: true
                            layer.effect: MultiEffect { blurEnabled: true; blur: 0.05 }
                        }
                    }

                    MouseArea {
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
