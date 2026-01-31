import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../Services"

PanelWindow {
    id: root
    
    // Fill the screen
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: "transparent"
    
    // Wayland layer shell setup
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    // Theme Colors
    readonly property color cBackground: ThemeService.background
    readonly property color cSurface: ThemeService.surface
    readonly property color cText: ThemeService.text
    readonly property color cAccent: ThemeService.accent
    readonly property color cHover: ThemeService.surface_variant

    function applyWallpaper(path) {
        // Set wallpaper with swww, generate colors with matugen AND wallust
        // This will apply the theme system-wide
        var fullCmd = `swww img '${path}' --transition-type grow --transition-pos 0.5,0.5 --transition-duration 1 && \\
                       matugen image '${path}' --type scheme-fruit-salad --mode dark && \\
                       wallust run '${path}' && \\
                       echo '${path}' > /home/zoro/.cache/current_wallpaper`

        wallpaperProcess.command = ["sh", "-c", fullCmd];
        wallpaperProcess.running = true;
    }

    Rectangle {
        anchors.centerIn: parent
        width: 1100
        height: 750
        color: cBackground
        border.color: cSurface
        border.width: 1
        radius: 12
        clip: true

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // Sidebar
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 200
                color: Qt.darker(cBackground, 1.2)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10

                    Text {
                        text: "Wallpapers"
                        font.pointSize: 18
                        font.bold: true
                        color: cAccent
                        Layout.bottomMargin: 20
                    }

                    // Nav Buttons
                    Repeater {
                        model: ["Local", "Wallhaven"]
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            height: 40
                            radius: 8
                            color: stack.currentIndex === index ? cAccent : (hoverHandler.hovered ? cSurface : "transparent")
                            
                            HoverHandler { id: hoverHandler }
                            
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: stack.currentIndex === index ? cBackground : cText
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    stack.currentIndex = index
                                    if (index === 1 && WallhavenService.results.length === 0) {
                                        WallhavenService.search("") // Initial load
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true } // Spacer

                    Button {
                        text: "Close"
                        Layout.fillWidth: true
                        
                        contentItem: Text {
                            text: parent.text
                            color: cText
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: parent.hovered ? cSurface : "transparent"
                            border.color: cSurface
                            radius: 8
                        }
                        onClicked: Qt.quit()
                    }
                }
            }

            // Content Area
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"
                clip: true

                StackLayout {
                    id: stack
                    anchors.fill: parent
                    anchors.margins: 20
                    currentIndex: 0

                    // --- Local Tab ---
                    Item {
                        Component.onCompleted: LocalWallpaperService.scan()
                        
                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 15

                            Text {
                                text: "Local Library"
                                color: cText
                                font.pointSize: 14
                                font.bold: true
                            }

                            GridView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                cellWidth: 215
                                cellHeight: 160
                                clip: true
                                model: LocalWallpaperService.wallpapers
                                
                                delegate: Item {
                                    width: 205
                                    height: 150
                                    
                                    Rectangle {
                                        anchors.fill: parent
                                        color: "transparent"
                                        radius: 8
                                        clip: true
                                        border.color: hoverHandler.hovered ? cAccent : "transparent"
                                        border.width: 2

                                        Image {
                                            source: "file://" + modelData
                                            anchors.fill: parent
                                            fillMode: Image.PreserveAspectCrop
                                            smooth: true
                                        }

                                        HoverHandler { id: hoverHandler }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: root.applyWallpaper(modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // --- Wallhaven Tab ---
                    Item {
                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 15

                            // Search Bar
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                TextField {
                                    id: searchInput
                                    placeholderText: "Search Wallhaven..."
                                    Layout.fillWidth: true
                                    font.pointSize: 11
                                    color: cText
                                    background: Rectangle {
                                        color: cSurface
                                        radius: 8
                                        border.color: parent.activeFocus ? cAccent : "transparent"
                                    }
                                    onAccepted: WallhavenService.search(text)
                                }

                                Button {
                                    text: "Search"
                                    background: Rectangle {
                                        color: cAccent
                                        radius: 8
                                    }
                                    contentItem: Text {
                                        text: parent.text
                                        color: cBackground
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    onClicked: WallhavenService.search(searchInput.text)
                                }
                            }

                            // Filters
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                ComboBox {
                                    id: sortingCombo
                                    model: ["relevance", "random", "date_added", "views", "favorites", "toplist"]
                                    implicitWidth: 120
                                    onCurrentTextChanged: {
                                        WallhavenService.sorting = currentText
                                        WallhavenService.search(searchInput.text)
                                    }
                                }

                                ComboBox {
                                    id: topRangeCombo
                                    visible: sortingCombo.currentText === "toplist"
                                    model: ["1d", "3d", "1w", "1M", "3M", "6M", "1y"]
                                    implicitWidth: 80
                                    onCurrentTextChanged: {
                                        WallhavenService.topRange = currentText
                                        WallhavenService.search(searchInput.text)
                                    }
                                }

                                RowLayout {
                                    spacing: 5
                                    CheckBox { text: "SFW"; checked: true; onCheckedChanged: updatePurity() }
                                    CheckBox { text: "Sketchy"; checked: true; onCheckedChanged: updatePurity() }
                                    CheckBox { text: "NSFW"; checked: true; onCheckedChanged: updatePurity() }
                                    
                                    function updatePurity() {
                                        var p = ""
                                        p += children[0].checked ? "1" : "0"
                                        p += children[1].checked ? "1" : "0"
                                        p += children[2].checked ? "1" : "0"
                                        WallhavenService.purity = p
                                        WallhavenService.search(searchInput.text)
                                    }
                                }
                            }

                            // Results Grid
                            GridView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                cellWidth: 215
                                cellHeight: 160
                                clip: true
                                model: WallhavenService.results
                                
                                delegate: Item {
                                    width: 205
                                    height: 150
                                    
                                    Rectangle {
                                        anchors.fill: parent
                                        color: cSurface
                                        radius: 8
                                        clip: true
                                        border.color: hoverHandler.hovered ? cAccent : "transparent"
                                        border.width: 2

                                        Image {
                                            source: modelData.thumbs.small
                                            anchors.fill: parent
                                            fillMode: Image.PreserveAspectCrop
                                            asynchronous: true
                                        }

                                        // Hover Overlay
                                        Rectangle {
                                            anchors.fill: parent
                                            color: "#000000"
                                            opacity: hoverHandler.hovered ? 0.4 : 0
                                            Behavior on opacity { NumberAnimation { duration: 150 } }
                                            
                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.resolution
                                                color: "white"
                                                font.bold: true
                                                visible: hoverHandler.hovered
                                            }
                                        }

                                        HoverHandler { id: hoverHandler }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: WallhavenService.download(modelData.path, modelData.id, root.applyWallpaper)
                                        }
                                    }
                                }
                            }

                            // Pagination & Status
                            RowLayout {
                                Layout.fillWidth: true
                                
                                Text {
                                    text: WallhavenService.loading ? "Loading..." : ""
                                    color: cText
                                    visible: WallhavenService.loading
                                }
                                
                                Item { Layout.fillWidth: true }
                                
                                Button {
                                    text: "<"
                                    enabled: WallhavenService.currentPage > 1
                                    onClicked: WallhavenService.prevPage()
                                    background: Rectangle { color: parent.enabled ? cSurface : "transparent"; radius: 4 }
                                    contentItem: Text { text: parent.text; color: cText; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                }
                                
                                Text {
                                    text: WallhavenService.currentPage + " / " + WallhavenService.lastPage
                                    color: cText
                                }
                                
                                Button {
                                    text: ">"
                                    enabled: WallhavenService.currentPage < WallhavenService.lastPage
                                    onClicked: WallhavenService.nextPage()
                                    background: Rectangle { color: parent.enabled ? cSurface : "transparent"; radius: 4 }
                                    contentItem: Text { text: parent.text; color: cText; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Process component to apply wallpaper and update colors
    Process {
        id: wallpaperProcess
        property string wallpaperPath

        stdout: StdioCollector {
            onStreamFinished: {
                // Reload theme to pick up new colors after wallpaper change
                ThemeService.updateColors();
            }
        }
    }
}
