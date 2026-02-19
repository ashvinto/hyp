import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../Services"

Item {
    id: root
    
    readonly property color cText: ThemeService.text
    readonly property color cAccent: ThemeService.accent
    readonly property color cDim: ThemeService.text_dim
    readonly property color cCard: Qt.rgba(1, 1, 1, 0.04)

    property date displayDate: new Date()
    property int currentMonth: displayDate.getMonth()
    property int currentYear: displayDate.getFullYear()
    
    function nextMonth() {
        displayDate = new Date(currentYear, currentMonth + 1, 1)
        updateModel()
    }
    
    function prevMonth() {
        displayDate = new Date(currentYear, currentMonth - 1, 1)
        updateModel()
    }
    
    function updateModel() {
        currentMonth = displayDate.getMonth()
        currentYear = displayDate.getFullYear()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 40
        spacing: 30

        // Header
        RowLayout {
            Layout.fillWidth: true
            
            ColumnLayout {
                spacing: 2
                Text {
                    text: Qt.formatDate(displayDate, "MMMM")
                    color: cText
                    font.pixelSize: 42
                    font.bold: true
                }
                Text {
                    text: currentYear
                    color: cAccent
                    font.pixelSize: 22
                    font.bold: true
                }
            }
            
            Item { Layout.fillWidth: true }
            
            RowLayout {
                spacing: 15
                IconButton {
                    text: "󰁍"
                    onClicked: prevMonth()
                }
                IconButton {
                    text: "󰁔"
                    onClicked: nextMonth()
                }
            }
        }

        // Calendar Grid Container
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: cCard
            radius: 24
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.1)
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 30
                spacing: 20

                // Week days header
                RowLayout {
                    Layout.fillWidth: true
                    Repeater {
                        model: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                        delegate: Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData
                            color: cDim
                            font.bold: true
                            font.pixelSize: 13
                        }
                    }
                }

                // Days grid
                GridLayout {
                    id: daysGrid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 7
                    rowSpacing: 10
                    columnSpacing: 10

                    Repeater {
                        model: 42 // 6 weeks
                        delegate: Rectangle {
                            id: dayRect
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 12
                            
                            readonly property var dateInfo: getDateForIndex(index)
                            readonly property bool isCurrentMonth: dateInfo.getMonth() === root.currentMonth
                            readonly property bool isToday: {
                                var today = new Date()
                                return dateInfo.getDate() === today.getDate() && 
                                       dateInfo.getMonth() === today.getMonth() && 
                                       dateInfo.getFullYear() === today.getFullYear()
                            }

                            color: isToday ? cAccent : (isCurrentMonth ? Qt.rgba(1, 1, 1, 0.05) : "transparent")
                            opacity: isCurrentMonth ? 1.0 : 0.3
                            
                            Text {
                                anchors.centerIn: parent
                                text: dateInfo.getDate()
                                color: isToday ? "black" : cText
                                font.bold: isToday
                                font.pixelSize: 16
                            }
                        }
                    }
                }
            }
        }
    }

    function getDateForIndex(index) {
        var firstDayOfMonth = new Date(currentYear, currentMonth, 1)
        // Adjust for Monday start (JS 0 is Sunday)
        var startOffset = firstDayOfMonth.getDay() - 1
        if (startOffset < 0) startOffset = 6
        
        return new Date(currentYear, currentMonth, index - startOffset + 1)
    }

    component IconButton: Rectangle {
        property string text: ""
        signal clicked()
        width: 44; height: 44; radius: 22
        color: hover.hovered ? Qt.rgba(cAccent.r, cAccent.g, cAccent.b, 0.2) : cCard
        border.color: hover.hovered ? cAccent : Qt.rgba(1, 1, 1, 0.1)
        border.width: 1
        Text {
            anchors.centerIn: parent
            text: parent.text
            color: hover.hovered ? cAccent : cText
            font.pixelSize: 20
            font.family: "Symbols Nerd Font"
        }
        MouseArea { anchors.fill: parent; onClicked: parent.clicked() }
        HoverHandler { id: hover }
    }
}
