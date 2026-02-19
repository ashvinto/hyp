import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../Services" as Services

PanelWindow {
    id: root

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "qs-launcher"

    readonly property color cBg: (typeof Services.ThemeService !== "undefined" && Services.ThemeService.backgroundDark) ? Services.ThemeService.backgroundDark : "#11111b"
    readonly property color cSurface: (typeof Services.ThemeService !== "undefined" && Services.ThemeService.surface) ? Services.ThemeService.surface : "#1e1e2e"
    readonly property color cAccent: (typeof Services.ThemeService !== "undefined" && Services.ThemeService.accent) ? Services.ThemeService.accent : "#cba6f7"
    readonly property color cText: (typeof Services.ThemeService !== "undefined" && Services.ThemeService.text) ? Services.ThemeService.text : "#cdd6f4"
    readonly property color cDim: (typeof Services.ThemeService !== "undefined" && Services.ThemeService.text_dim) ? Services.ThemeService.text_dim : "#6c7086"

    // Animation Controller
    property bool active: false
    Component.onCompleted: {
        Services.AppService.scan()
        searchInput.forceActiveFocus()
        active = true
    }

    function close() {
        active = false
        exitTimer.start()
    }
    Timer { id: exitTimer; interval: 500; onTriggered: Qt.quit() }

    property string filterText: ""
    property string webAnswer: ""
    property string webSource: ""
    property int scrollDir: 0

    // Local Web Search Process (HTML Scraper)
    Timer {
        id: webTimer
        interval: 800
        repeat: false
        onTriggered: {
            if (filterText.length > 3 && !filterText.startsWith("/") && !filterText.startsWith("def ") && !filterText.startsWith("g ")) {
                webAnswer = "Searching..."
                var cmd = "curl -sL -A 'Mozilla/5.0' 'https://lite.duckduckgo.com/lite/?q=" + encodeURIComponent(filterText) + "' | python3 -c \"import sys, re, html; " +
                          "try: " +
                          "  content = sys.stdin.read(); " +
                          "  match = re.search(r'<td class=\\\"result-snippet\\\">\\s*(.*?)\\s*</td>', content, re.DOTALL); " +
                          "  if match: " +
                          "    text = re.sub('<[^<]+?>', '', match.group(1)); " +
                          "    text = html.unescape(text).strip(); " +
                          "    print(text[:350]); " +
                          "  else: print(''); " +
                          "except: print('');\""
                webProcess.command = ["sh", "-c", cmd]
                webProcess.running = true
            }
        }
    }

    Process {
        id: webProcess
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim() !== "") {
                    webAnswer = text.trim()
                    webSource = "Web"
                } else {
                    webAnswer = ""
                }
            }
        }
    }

    property var commandResult: {
        if (filterText === "") return null
        if (filterText.startsWith("g ")) return { type: "web_search", label: "Google Search", icon: "󰊭", value: filterText.substring(2) }
        if (filterText.startsWith("/")) return { type: "file", label: "File Search", icon: "󰈞", value: filterText.substring(1) }
        if (filterText.startsWith("def ")) {
            Services.AppService.lookupWord(filterText.substring(4))
            return { type: "dict", label: "Definition", icon: "", value: Services.AppService.definition || "Searching..." }
        }
        if (/^[0-9+\-*/().\s]+$/.test(filterText)) {
            try {
                var res = eval(filterText)
                if (res !== undefined && res.toString() !== filterText) 
                    return { type: "math", value: res, label: "Result", icon: "󰃬" }
            } catch(e) {}
        }
        if (filterText.toLowerCase() === "ai") return { type: "hub", label: "AI Hub", icon: "󰚩", cmd: "zero-ai" }
        if (webAnswer !== "") return { type: "web", label: "Quick Answer", icon: "󰊭", value: webAnswer }
        return null
    }

    property var filteredApps: {
        var list = Services.AppService.apps
        if (filterText === "" || filterText.startsWith("/") || filterText.startsWith("def ") || filterText.startsWith("g ")) return list 
        var lowerFilter = filterText.toLowerCase()
        return list.filter(app => app.name.toLowerCase().includes(lowerFilter))
    }

    function runLauncher() {
        if (commandResult) {
            if (commandResult.type === "web_search") Quickshell.execDetached(["xdg-open", "https://google.com/search?q=" + encodeURIComponent(commandResult.value)])
            else if (commandResult.type === "math") Quickshell.execDetached(["sh", "-c", "printf '" + commandResult.value + "' | wl-copy"])
            else if (commandResult.type === "hub") Quickshell.execDetached(["bash", "-c", commandResult.cmd])
            else if (commandResult.type === "web") Quickshell.execDetached(["xdg-open", "https://google.com/search?q=" + encodeURIComponent(filterText)])
            root.close()
            return
        }
        if (filterText.startsWith("/") && Services.AppService.files.length > 0) {
            var fileIndex = fileList.currentIndex >= 0 ? fileList.currentIndex : 0
            Quickshell.execDetached(["xdg-open", Services.AppService.files[fileIndex].path])
            root.close()
            return
        }
        if (filteredApps.length > 0) {
            var index = gridView.currentIndex >= 0 ? gridView.currentIndex : 0
            Services.AppService.launch(filteredApps[index].exec)
            root.close()
        }
    }

    Timer {
        id: scrollTimer; interval: 16; repeat: true; running: root.scrollDir !== 0
        onTriggered: gridView.contentY = Math.max(0, Math.min(gridView.contentHeight - gridView.height, gridView.contentY + (8 * root.scrollDir)))
    }

    // Semi-transparent background dim
    Rectangle { 
        anchors.fill: parent; color: "black"
        opacity: root.active ? 0.5 : 0
        Behavior on opacity { NumberAnimation { duration: 400 } }
        MouseArea { anchors.fill: parent; onClicked: root.close() } 
    }

    Rectangle {
        id: mainWindow
        anchors.centerIn: parent
        width: 1000; height: 650
        radius: 32; border.color: Qt.rgba(1, 1, 1, 0.1); border.width: 1; clip: true
        color: "#181825" 
        
        layer.enabled: true
        layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 0.6; shadowOpacity: 0.4; shadowVerticalOffset: 15 }

        // --- DRAMATIC ENTRY/EXIT ANIMATIONS ---
        opacity: root.active ? 1.0 : 0
        scale: root.active ? 1.0 : 0.85 // Start smaller for bigger impact
        
        property real yOffset: root.active ? 0 : 60 // Rise up from bottom
        transform: Translate { y: mainWindow.yOffset }

        Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutExpo } }
        Behavior on scale { NumberAnimation { duration: 600; easing.type: Easing.OutBack } }
        Behavior on yOffset { NumberAnimation { duration: 600; easing.type: Easing.OutBack } }

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 25; spacing: 15

            // --- SEARCH BAR ---
            Rectangle {
                Layout.fillWidth: true; height: 52; radius: 14
                color: Qt.rgba(0,0,0,0.3); border.color: searchInput.activeFocus ? cAccent : Qt.rgba(1,1,1,0.1); border.width: 1
                RowLayout {
                    anchors.fill: parent; anchors.margins: 15; spacing: 15
                    Text { text: "󰍉"; color: cAccent; font.pixelSize: 20; font.family: "Symbols Nerd Font" }
                    TextInput {
                        id: searchInput; Layout.fillWidth: true; verticalAlignment: TextInput.AlignVCenter
                        font.pixelSize: 16; color: "white"; clip: true
                        onTextChanged: {
                            root.filterText = text
                            root.webAnswer = ""
                            gridView.currentIndex = 0 // Reset selection on new search
                            fileList.currentIndex = 0
                            if (text.startsWith("/")) Services.AppService.searchFiles(text.substring(1))
                            else if (text.startsWith("def ")) Services.AppService.lookupWord(text.substring(4))
                            else if (!text.startsWith("g ")) webTimer.restart()
                        }
                        onAccepted: runLauncher()
                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Down) {
                                if (fileList.visible) fileList.incrementCurrentIndex()
                                else gridView.moveCurrentIndexDown()
                                event.accepted = true
                            } else if (event.key === Qt.Key_Up) {
                                if (fileList.visible) fileList.decrementCurrentIndex()
                                else gridView.moveCurrentIndexUp()
                                event.accepted = true
                            } else if (event.key === Qt.Key_Left) {
                                if (!fileList.visible) gridView.moveCurrentIndexLeft()
                                event.accepted = true
                            } else if (event.key === Qt.Key_Right) {
                                if (!fileList.visible) gridView.moveCurrentIndexRight()
                                event.accepted = true
                            }
                        }
                        Keys.onEscapePressed: root.close()
                    }
                }
            }

            // --- SMART RESULT ---
            Rectangle {
                Layout.fillWidth: true; height: (commandResult && commandResult.type !== "file") ? 100 : 0
                radius: 14; clip: true; opacity: (commandResult && commandResult.type !== "file") ? 1 : 0
                color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.12); border.color: cAccent; border.width: 1
                Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                Behavior on opacity { NumberAnimation { duration: 250 } }
                
                RowLayout {
                    anchors.fill: parent; anchors.margins: 20; spacing: 20
                    Text { text: commandResult ? commandResult.icon : ""; color: cAccent; font.pixelSize: 32; font.family: "Symbols Nerd Font" }
                    ColumnLayout {
                        spacing: 4; Layout.fillWidth: true
                        Text { text: commandResult ? commandResult.label : ""; color: cAccent; font.pixelSize: 10; font.bold: true }
                        Text { 
                            text: commandResult ? commandResult.value : ""
                            color: "white"; font.pixelSize: 14; font.weight: Font.Medium; wrapMode: Text.WordWrap; Layout.fillWidth: true; maximumLineCount: 3; elide: Text.ElideRight 
                        }
                    }
                }
                MouseArea { anchors.fill: parent; onClicked: runLauncher() }
            }

            // --- CONTENT AREA ---
            Item {
                Layout.fillWidth: true; Layout.fillHeight: true
                
                GridView {
                    id: gridView; anchors.fill: parent; 
                    cellWidth: 135; cellHeight: 145; clip: true; focus: true
                    model: root.filteredApps; visible: !filterText.startsWith("/") && !filterText.startsWith("def ") && !filterText.startsWith("g ")
                    
                    highlight: Rectangle {
                        width: 115; height: 130; radius: 20
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.18) }
                            GradientStop { position: 1.0; color: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.08) }
                        }
                        border.color: cAccent; border.width: 1
                    }
                    highlightFollowsCurrentItem: true
                    highlightMoveDuration: 350

                    delegate: Item {
                        width: gridView.cellWidth; height: gridView.cellHeight
                        
                        ColumnLayout {
                            anchors.centerIn: parent; spacing: 12
                            Item {
                                Layout.alignment: Qt.AlignHCenter; width: 72; height: 72
                                Image { 
                                    anchors.fill: parent; anchors.margins: 10; 
                                    source: modelData.icon ? ("image://icon/" + modelData.icon) : ""; 
                                    fillMode: Image.PreserveAspectFit; asynchronous: true 
                                }
                                
                                // Dramatic Cascading Entry for Icons
                                scale: root.active ? 1.0 : 0.2
                                opacity: root.active ? 1.0 : 0
                                Behavior on scale { NumberAnimation { duration: 700; easing.type: Easing.OutBack } }
                                Behavior on opacity { NumberAnimation { duration: 500 } }
                            }
                            Text { 
                                Layout.preferredWidth: 110; text: modelData.name; color: "white"
                                font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.WordWrap; opacity: gridView.currentIndex === index ? 1.0 : 0.7 
                            }
                        }
                        MouseArea { 
                            anchors.fill: parent; hoverEnabled: true; onEntered: gridView.currentIndex = index; onClicked: Services.AppService.launch(modelData.exec)
                            onPositionChanged: (m) => { var gy = mapToItem(mainWindow, m.x, m.y).y; if (gy > mainWindow.height - 60) root.scrollDir = 1; else if (gy < 120) root.scrollDir = -1; else root.scrollDir = 0 }
                        }
                    }
                }

                ListView {
                    id: fileList; anchors.fill: parent; spacing: 8; clip: true; visible: filterText.startsWith("/")
                    model: Services.AppService.files
                    currentIndex: 0
                    highlightFollowsCurrentItem: true
                    
                    delegate: Rectangle {
                        width: fileList.width; height: 52; radius: 12
                        color: (fileList.currentIndex === index || fHover.hovered) ? Qt.rgba(255,255,255,0.08) : "transparent"
                        border.color: (fileList.currentIndex === index || fHover.hovered) ? cAccent : "transparent"
                        border.width: 1
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 12; spacing: 15
                            Text { text: "󰈔"; color: cAccent; font.pixelSize: 22; font.family: "Symbols Nerd Font" }
                            ColumnLayout { spacing: 0; Layout.fillWidth: true; Text { text: modelData.name; color: "white"; font.bold: true; font.pixelSize: 14; elide: Text.ElideRight } Text { text: modelData.path; color: cDim; font.pixelSize: 9; elide: Text.ElideRight } }
                        }
                        MouseArea { id: fHover; anchors.fill: parent; hoverEnabled: true; onEntered: fileList.currentIndex = index; onClicked: { Quickshell.execDetached(["xdg-open", modelData.path]); Qt.quit() } }
                    }
                }
            }
        }
    }
}