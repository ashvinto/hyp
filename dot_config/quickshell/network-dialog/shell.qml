import QtQuick
import Quickshell
import "./UI"

ShellRoot {
    id: root

    // Use environment variables to pass data between processes
    readonly property string initialSsid: Quickshell.env("QS_WIFI_SSID") ?? ""
    readonly property string initialSecurity: Quickshell.env("QS_WIFI_SECURITY") ?? ""
    readonly property string initialMethod: Quickshell.env("QS_WIFI_METHOD") ?? "wpa"
    readonly property int initialSignal: parseInt(Quickshell.env("QS_WIFI_SIGNAL") ?? "100")

    NetworkDialog { 
        id: dialog
        connectionData: initialSsid !== "" ? {
            ssid: initialSsid,
            security: initialSecurity,
            method: initialMethod,
            signal: initialSignal
        } : null
    }
}
