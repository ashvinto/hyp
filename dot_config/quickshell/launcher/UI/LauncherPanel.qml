import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// 1. Alias the import to avoid "ReferenceError"
import "../Services" as Services

PanelWindow {
    id: root

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    MouseArea {
        anchors.fill: parent
        onClicked: Qt.quit()
        z: -1
    }

    // 2. Use the alias prefix for properties
    readonly property color cBg: Services.ThemeService.background
    readonly property color cSurface: Services.ThemeService.surface
    readonly property color cAccent: Services.ThemeService.accent
    readonly property color cText: Services.ThemeService.text
    readonly property color cDim: Services.ThemeService.text_dim

    Component.onCompleted: {
        Services.AppService.scan()
        searchInput.forceActiveFocus()
        loadRecentApps()
    }

    property string filterText: ""
    property string selectedCategory: "All"
    
    // Universal Command Parser
    property var commandResult: {
        if (filterText === "") return null
        
        // 1. Math Evaluation
        if (/^[0-9+\-*/().\s]+$/.test(filterText)) {
            try {
                var res = eval(filterText)
                if (res !== undefined && res !== filterText) 
                    return { type: "math", value: res, label: "Result" }
            } catch(e) {}
        }
        
        // 2. Web Search Shortcuts
        if (filterText.startsWith("g ")) return { type: "web", value: filterText.substring(2), label: "Google Search", icon: "󰊭" }
        if (filterText.startsWith("y ")) return { type: "web", value: filterText.substring(2), label: "YouTube Search", icon: "󰗃" }
        
        // 3. System Commands
        var sysCmds = {
            "reboot": { type: "sys", label: "Restart System", icon: "󰑓", cmd: "reboot" },
            "shutdown": { type: "sys", label: "Power Off", icon: "󰐥", cmd: "shutdown now" },
            "lock": { type: "sys", label: "Lock Screen", icon: "󰌾", cmd: "hyprlock" },
            "logout": { type: "sys", label: "Exit Hyprland", icon: "󰍃", cmd: "hyprctl dispatch exit" }
        }
        if (sysCmds[filterText.toLowerCase()]) return sysCmds[filterText.toLowerCase()]
        
        return null
    }

    // Scored Fuzzy Search
    property var filteredApps: {
        var list = Services.AppService.apps
        var filtered = list
        
        // 1. Filter by Category
        if (selectedCategory !== "All" && filterText === "") {
            filtered = list.filter(app => app.category === selectedCategory)
        }
        
        if (filterText === "") return filtered
        
        // 2. Fuzzy Search
        var lowerFilter = filterText.toLowerCase()
        var results = []
        
        for (var i = 0; i < list.length; i++) {
            var app = list[i]
            var lowerName = app.name.toLowerCase()
            
            if (lowerName === lowerFilter) app.score = 100
            else if (lowerName.startsWith(lowerFilter)) app.score = 80
            else if (lowerName.includes(lowerFilter)) app.score = 50
            else {
                var score = 0
                var filterIdx = 0
                for (var nameIdx = 0; nameIdx < lowerName.length && filterIdx < lowerFilter.length; nameIdx++) {
                    if (lowerName[nameIdx] === lowerFilter[filterIdx]) {
                        filterIdx++
                        score += 5
                    }
                }
                if (filterIdx === lowerFilter.length) app.score = score
                else continue
            }
            results.push(app)
        }
        return results.sort((a, b) => b.score - a.score)
    }

    function launchApp(app) {
        if (commandResult) {
            if (commandResult.type === "math") {
                Quickshell.execDetached(["sh", "-c", "printf '" + commandResult.value + "' | wl-copy"])
            } else if (commandResult.type === "web") {
                var engine = commandResult.label.includes("Google") ? "google.com/search?q=" : "youtube.com/results?search_query="
                Quickshell.execDetached(["xdg-open", "https://" + engine + encodeURIComponent(commandResult.value)])
            } else if (commandResult.type === "sys") {
                Quickshell.execDetached(["sh", "-c", commandResult.cmd])
            }
            Qt.quit()
            return
        }
        Services.AppService.launch(app.exec)
    }

    Rectangle {
        anchors.centerIn: parent
        width: 900
        height: 650
        color: Qt.rgba(cBg.r, cBg.g, cBg.b, 0.95)
        radius: 24
        border.color: Qt.rgba(1, 1, 1, 0.1)
        border.width: 1
        clip: true

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // SIDEBAR: CATEGORIES
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 180
                color: Qt.rgba(0, 0, 0, 0.2)
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 10
                    
                    Text { text: "CATEGORIES"; color: cDim; font.bold: true; font.pixelSize: 10; font.letterSpacing: 1 }
                    
                    Repeater {
                        model: ["All", "Internet", "Dev", "System", "Games", "Graphics", "Tools"]
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            height: 40; radius: 10
                            color: root.selectedCategory === modelData ? cSurface : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: root.selectedCategory === modelData ? cAccent : cText
                                font.bold: root.selectedCategory === modelData
                                font.pixelSize: 13
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    root.selectedCategory = modelData
                                    root.filterText = ""
                                    searchInput.text = ""
                                }
                            }
                        }
                    }
                    Item { Layout.fillHeight: true }
                }
            }

            // MAIN AREA
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                anchors.margins: 30
                spacing: 25

                // Search Bar
                Rectangle {
                    Layout.fillWidth: true
                    height: 55
                    color: cSurface
                    radius: 16
                    border.color: searchInput.activeFocus ? cAccent : "transparent"
                    border.width: 2
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 15; spacing: 15
                        Text { text: "󰍉"; color: cAccent; font.pixelSize: 20; font.family: "Symbols Nerd Font" }
                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            verticalAlignment: TextInput.AlignVCenter
                            font.pixelSize: 16; color: cText; clip: true
                            onTextChanged: { root.filterText = text; gridView.currentIndex = 0 }
                            Keys.onDownPressed: gridView.forceActiveFocus()
                            Keys.onEscapePressed: Qt.quit()
                            onAccepted: if (commandResult || root.filteredApps.length > 0) launchApp(root.filteredApps[0])
                        }
                    }
                }

                // Spotlight Result Pill
                Rectangle {
                    Layout.fillWidth: true
                    height: 60
                    radius: 16
                    color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.1)
                    border.color: cAccent
                    border.width: 1
                    visible: commandResult !== null
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 15; spacing: 15
                        Text { 
                            text: commandResult ? (commandResult.icon || "󰃬") : ""
                            color: cAccent; font.pixelSize: 22; font.family: "Symbols Nerd Font" 
                        }
                        ColumnLayout {
                            spacing: 0
                            Text { text: commandResult ? commandResult.label : ""; color: cDim; font.pixelSize: 10; font.bold: true }
                            Text { text: commandResult ? (commandResult.value || filterText) : ""; color: cText; font.pixelSize: 16; font.bold: true }
                        }
                        Item { Layout.fillWidth: true }
                        Text { text: "Press Enter to execute"; color: cDim; font.pixelSize: 10; font.italic: true }
                    }
                }

                GridView {
                    id: gridView
                    Layout.fillWidth: true; Layout.fillHeight: true
                    cellWidth: 120; cellHeight: 140; clip: true; focus: true
                    model: root.filteredApps
                    
                    highlight: Rectangle { color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.15); radius: 16; border.color: cAccent; border.width: 1 }
                    delegate: Item {
                        width: 110; height: 130
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 10; spacing: 10
                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                width: 64; height: 64; radius: 16; color: Qt.rgba(1, 1, 1, 0.03)
                                Image { anchors.fill: parent; anchors.margins: 10; source: modelData.icon ? ("image://icon/" + modelData.icon) : ""; fillMode: Image.PreserveAspectFit; asynchronous: true }
                            }
                            Text { Layout.fillWidth: true; text: modelData.name; color: cText; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.WordWrap }
                        }
                        MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: gridView.currentIndex = index; onClicked: launchApp(modelData) }
                    }
                }
            }
        }
    }
}
