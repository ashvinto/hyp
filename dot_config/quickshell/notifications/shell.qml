import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "./UI"

ShellRoot {
    id: root

    NotificationServer {
        id: server
    }

    property var activeNotifications: []

    // The signal in Quickshell is onNotification
    Connections {
        target: server
        function onNotification(notification) {
            console.log("New notification received: " + notification.summary)
            var obj = notificationComponent.createObject(root, { 
                "notification": notification,
                "yOffset": root.activeNotifications.length * 95,
                "active": true
            })
            root.activeNotifications.push(obj)
            
            obj.Component.onDestruction.connect(() => {
                var idx = root.activeNotifications.indexOf(obj)
                if (idx !== -1) {
                    root.activeNotifications.splice(idx, 1)
                    for (var i = idx; i < root.activeNotifications.length; i++) {
                        root.activeNotifications[i].yOffset = i * 95
                    }
                }
            })
        }
    }

    Component {
        id: notificationComponent
        
        Variants {
            model: Quickshell.screens
            
            NotificationPopup {
                property var modelData
                screen: modelData
            }
        }
    }
}
