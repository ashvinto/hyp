pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    property string city: "..."
    property string icon: "󰖐"
    property string temp: "0°C"
    property string description: "No Data"
    property int humidity: 0
    property real windSpeed: 0

    Component.onCompleted: update()

    function update() {
        console.log("[WeatherService] Fetching from wttr.in...")
        var xhr = new XMLHttpRequest()
        // Using wttr.in with JSON format j1
        xhr.open("GET", "https://wttr.in?format=j1")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var json = JSON.parse(xhr.responseText)
                        var current = json.current_condition[0]
                        var area = json.nearest_area[0]
                        
                        root.temp = current.temp_C + "°C"
                        root.description = current.weatherDesc[0].value
                        root.humidity = parseInt(current.humidity)
                        root.windSpeed = parseFloat(current.windspeedKmph)
                        root.city = area.areaName[0].value
                        
                        root.icon = getWeatherIcon(current.weatherCode)
                        console.log("[WeatherService] wttr.in update success: " + root.temp)
                    } catch(e) {
                        console.error("[WeatherService] Parse error:", e)
                    }
                } else {
                    console.error("[WeatherService] API error: " + xhr.status)
                }
            }
        }
        xhr.send()
    }

    function getWeatherIcon(code) {
        // wttr.in uses WWO codes
        var icons = {
            "113": "󰖙", // Clear/Sunny
            "116": "󰖕", // Partly Cloudy
            "119": "󰖐", // Cloudy
            "122": "󰖐", // Overcast
            "143": "󰖑", // Mist
            "176": "󰖗", // Patchy rain nearby
            "200": "󰖓", // Thundery outbreaks nearby
            "248": "󰖑", // Fog
            "263": "󰖗", // Patchy light drizzle
            "266": "󰖗", // Light drizzle
            "293": "󰖖", // Patchy light rain
            "296": "󰖖", // Light rain
            "299": "󰖖", // Moderate rain at times
            "302": "󰖖", // Moderate rain
            "305": "󰖖", // Heavy rain at times
            "308": "󰖖", // Heavy rain
            "353": "󰖗", // Light rain shower
            "389": "󰖓", // Moderate or heavy rain with thunder
        }
        return icons[code] || "󰖐"
    }

    Timer {
        interval: 1800000 // 30 mins
        running: true
        repeat: true
        onTriggered: update()
    }
}
