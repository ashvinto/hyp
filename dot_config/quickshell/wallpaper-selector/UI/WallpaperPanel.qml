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

    // Preview State
    property string previewPath: ""
    property bool previewVisible: false
    property bool isDownloading: false
    property var selectedWallpaperData: null

    function applyWallpaper(path) {
        // Set wallpaper with swww, generate colors with wallust
        var fullCmd = "swww img '" + path + "' --transition-type grow --transition-pos 0.5,0.5 --transition-duration 1 && " +
                       "wallust run '" + path + "' && " +
                       "echo '" + path + "' > /home/zoro/.cache/current_wallpaper"

        wallpaperProcess.command = ["sh", "-c", fullCmd]
        wallpaperProcess.running = true
    }

    function updateWallhavenSettings() {
        if (!sfwCb) return 
        
        var p = ""
        p += sfwCb.checked ? "1" : "0"
        p += sketchyCb.checked ? "1" : "0"
        p += nsfwCb.checked ? "1" : "0"
        WallhavenService.purity = p

        var c = ""
        c += generalCb.checked ? "1" : "0"
        c += animeCb.checked ? "1" : "0"
        c += peopleCb.checked ? "1" : "0"
        WallhavenService.categories = c
        
        WallhavenService.search(searchInput.text)
    }

    function formatBytes(bytes) {
        if (!bytes || bytes === 0) return '0 B'
        const k = 1024
        const sizes = ['B', 'KB', 'MB', 'GB']
        const i = Math.floor(Math.log(bytes) / Math.log(k))
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
    }

    // Main Container
    Rectangle {
        anchors.centerIn: parent
        width: 1100
        height: 750
        color: cBackground
        border.color: cSurface
        border.width: 1
        radius: 12
        clip: true
        
        visible: !root.previewVisible
        opacity: root.previewVisible ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 300 } }

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
                                        root.updateWallhavenSettings()
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Button {
                        text: "Close"
                        Layout.fillWidth: true
                        contentItem: Text { text: parent.text; color: cText; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { color: parent.hovered ? cSurface : "transparent"; border.color: cSurface; radius: 8 }
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
                            Text { text: "Local Library"; color: cText; font.pointSize: 14; font.bold: true }
                            GridView {
                                Layout.fillWidth: true; Layout.fillHeight: true; cellWidth: 215; cellHeight: 160; clip: true; model: LocalWallpaperService.wallpapers
                                delegate: Item {
                                    width: 205; height: 150
                                    Rectangle {
                                        anchors.fill: parent; color: "transparent"; radius: 8; clip: true; border.color: hoverHandler.hovered ? cAccent : "transparent"; border.width: 2
                                        Image { source: "file://" + modelData; anchors.fill: parent; fillMode: Image.PreserveAspectCrop; smooth: true }
                                        HoverHandler { id: hoverHandler }
                                        MouseArea { anchors.fill: parent; onClicked: root.applyWallpaper(modelData) }
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
                                    background: Rectangle { color: cSurface; radius: 8; border.color: parent.activeFocus ? cAccent : "transparent" }
                                    onAccepted: WallhavenService.search(text)
                                }
                                Button {
                                    text: "Search"
                                    background: Rectangle { color: cAccent; radius: 8 }
                                    contentItem: Text { text: parent.text; color: cBackground; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                    onClicked: WallhavenService.search(searchInput.text)
                                }
                            }

                            // Filters
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 15
                                ComboBox {
                                    id: sortingCombo
                                    model: ["relevance", "random", "date_added", "views", "favorites", "toplist"]
                                    implicitWidth: 120
                                    onCurrentTextChanged: { WallhavenService.sorting = currentText; WallhavenService.search(searchInput.text) }
                                }
                                ComboBox {
                                    id: topRangeCombo
                                    visible: sortingCombo.currentText === "toplist"
                                    model: ["1d", "3d", "1w", "1M", "3M", "6M", "1y"]
                                    implicitWidth: 80
                                    onCurrentTextChanged: { WallhavenService.topRange = currentText; WallhavenService.search(searchInput.text) }
                                }
                                RowLayout {
                                    spacing: 2
                                    CheckBox { id: sfwCb; text: "SFW"; checked: true; onCheckedChanged: root.updateWallhavenSettings() }
                                    CheckBox { id: sketchyCb; text: "Sketchy"; checked: true; onCheckedChanged: root.updateWallhavenSettings() }
                                    CheckBox { id: nsfwCb; text: "NSFW"; checked: false; onCheckedChanged: root.updateWallhavenSettings() }
                                }
                                Rectangle { width: 1; height: 20; color: cSurface; Layout.leftMargin: 5; Layout.rightMargin: 5 }
                                RowLayout {
                                    spacing: 2
                                    CheckBox { id: generalCb; text: "General"; checked: true; onCheckedChanged: root.updateWallhavenSettings() }
                                    CheckBox { id: animeCb; text: "Anime"; checked: true; onCheckedChanged: root.updateWallhavenSettings() }
                                    CheckBox { id: peopleCb; text: "People"; checked: true; onCheckedChanged: root.updateWallhavenSettings() }
                                }
                            }

                            GridView {
                                id: wallhavenGrid
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                cellWidth: 215
                                cellHeight: 160
                                clip: true
                                model: WallhavenService.results
                                onContentYChanged: { if (contentY + height >= contentHeight - 500) WallhavenService.nextPage() }
                                delegate: Item {
                                    width: 205; height: 150
                                    Rectangle {
                                        anchors.fill: parent
                                        color: cSurface
                                        radius: 8
                                        clip: true
                                        border.color: hoverHandler.hovered ? cAccent : "transparent"
                                        border.width: 2
                                        Image { source: modelData.thumbs.small; anchors.fill: parent; fillMode: Image.PreserveAspectCrop; asynchronous: true }
                                        Rectangle {
                                            anchors.fill: parent
                                            color: "#000000"
                                            opacity: hoverHandler.hovered ? 0.4 : 0
                                            Behavior on opacity { NumberAnimation { duration: 150 } }
                                            Text { anchors.centerIn: parent; text: modelData.resolution; color: "white"; font.bold: true; visible: hoverHandler.hovered }
                                        }
                                        HoverHandler { id: hoverHandler }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                root.isDownloading = true
                                                root.selectedWallpaperData = modelData
                                                WallhavenService.download(modelData.path, modelData.id, function(path) {
                                                    root.previewPath = path
                                                    root.previewVisible = true
                                                    root.isDownloading = false
                                                })
                                            }
                                        }
                                    }
                                }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                height: 30
                                Text { text: WallhavenService.loading ? "Loading more..." : ("Showing " + WallhavenService.results.length + " wallpapers"); color: cText; font.pixelSize: 10; opacity: 0.7 }
                                Item { Layout.fillWidth: true }
                                Text { text: "Page " + WallhavenService.currentPage + " of " + WallhavenService.lastPage; color: cText; font.pixelSize: 10; opacity: 0.7 }
                            }
                        }
                    }
                }
            }
        }
    }

    // --- ENHANCED PREVIEW OVERLAY ---
    Rectangle {
        id: previewOverlay
        anchors.fill: parent
        color: "black"
        visible: root.previewVisible
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 400 } }
        
        focus: visible
        Keys.onEscapePressed: discardBtn.clicked()

        // Background Blur Effect
        Image {
            id: bgBlur
            anchors.fill: parent
            source: "file://" + root.previewPath
            fillMode: Image.PreserveAspectCrop
            opacity: 0.4
            
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 1.0
            }
        }

        // Content
        RowLayout {
            anchors.fill: parent
            anchors.margins: 50
            spacing: 40

            // 1. Image Preview
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "black"
                radius: 20
                clip: true
                
                layer.enabled: true
                layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 20; shadowColor: "black" }

                Image {
                    anchors.fill: parent
                    source: "file://" + root.previewPath
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }
                
                // Mock UI Overlay (Desktop Simulation)
                Item {
                    anchors.fill: parent
                    opacity: desktopSimToggle.checked ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    
                    // Top Bar Mock
                    Rectangle {
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.topMargin: 10
                        width: parent.width * 0.9
                        height: 30
                        radius: 15
                        color: Qt.rgba(0,0,0,0.6)
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 15
                            Text { text: "󰣇"; color: "white"; font.pixelSize: 14 }
                            Item { Layout.fillWidth: true }
                            Text { text: "12:30 PM"; color: "white"; font.bold: true; font.pixelSize: 12 }
                            Item { Layout.fillWidth: true }
                            Text { text: "󰂄 85%"; color: "white"; font.pixelSize: 12 }
                        }
                    }
                    
                    // Widget Mock
                    Rectangle {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 30
                        width: 200
                        height: 280
                        radius: 20
                        color: Qt.rgba(0,0,0,0.5)
                        border.color: Qt.rgba(1,1,1,0.1)
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            Text { text: "Quick Settings"; color: "white"; font.bold: true; font.pixelSize: 16 }
                            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.1) }
                            Item { Layout.fillHeight: true }
                            RowLayout {
                                spacing: 10
                                Rectangle { width: 40; height: 40; radius: 20; color: cAccent }
                                Rectangle { width: 40; height: 40; radius: 20; color: Qt.rgba(1,1,1,0.1) }
                                Rectangle { width: 40; height: 40; radius: 20; color: Qt.rgba(1,1,1,0.1) }
                            }
                        }
                    }
                }
            }

            // 2. Info Sidebar
            Rectangle {
                Layout.preferredWidth: 320
                Layout.fillHeight: true
                color: Qt.rgba(0, 0, 0, 0.6)
                radius: 20
                border.color: Qt.rgba(1, 1, 1, 0.1)
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 30
                    spacing: 25

                    Text { text: "Wallpaper Details"; color: cAccent; font.bold: true; font.pointSize: 18 }

                    ColumnLayout {
                        spacing: 15
                        InfoRow { label: "Resolution"; value: root.selectedWallpaperData ? root.selectedWallpaperData.resolution : "N/A" }
                        InfoRow { label: "Category"; value: root.selectedWallpaperData ? root.selectedWallpaperData.category : "N/A" }
                        InfoRow { label: "Purity"; value: root.selectedWallpaperData ? root.selectedWallpaperData.purity : "N/A" }
                        InfoRow { label: "Size"; value: root.formatBytes(root.selectedWallpaperData ? root.selectedWallpaperData.file_size : 0) }
                    }

                    Item { Layout.fillHeight: true }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Desktop Simulation"; color: "white"; font.pixelSize: 12; Layout.fillWidth: true }
                        Switch { id: desktopSimToggle; checked: true }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        
                        Button {
                            text: "Apply Wallpaper"
                            Layout.fillWidth: true
                            onClicked: {
                                root.applyWallpaper(root.previewPath)
                                root.previewVisible = false
                            }
                            background: Rectangle { color: cAccent; radius: 10; implicitHeight: 50 }
                            contentItem: Text { text: parent.text; color: "black"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        }

                        Button {
                            id: discardBtn
                            text: "Discard"
                            Layout.fillWidth: true
                            onClicked: {
                                var delProc = Qt.createQmlObject("import Quickshell.Io; Process { command: ['rm', '-f', '" + root.previewPath + "'] }", root, "discard_del")
                                delProc.running = true
                                root.previewVisible = false
                            }
                            background: Rectangle { color: "transparent"; border.color: "white"; border.width: 1; radius: 10; implicitHeight: 50 }
                            contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        }
                    }
                }
            }
        }
    }

    // --- DOWNLOADING OVERLAY ---
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.7)
        visible: root.isDownloading
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 15
            BusyIndicator { running: root.isDownloading; palette.accent: cAccent; Layout.alignment: Qt.AlignHCenter }
            Text { text: "Fetching High Resolution..."; color: "white"; font.bold: true; font.pixelSize: 14 }
        }
    }

    component InfoRow: RowLayout {
        property string label: ""
        property string value: ""
        Text { text: label; color: Qt.rgba(1,1,1,0.5); font.pixelSize: 12; Layout.fillWidth: true }
        Text { text: value; color: "white"; font.bold: true; font.pixelSize: 13 }
    }

    Process {
        id: wallpaperProcess
        stdout: StdioCollector { onStreamFinished: { ThemeService.updateColors(); } }
    }
}
