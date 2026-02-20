pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    property string city: "Weather"
    property string icon: "󰖐"
    property string temp: "0°C"
    property string description: "No Data"
    property int humidity: 0
    property real windSpeed: 0

    Component.onCompleted: update()

    function update() {
        console.log("[WeatherService] Fetching location...")
        var locXhr = new XMLHttpRequest()
        // ip-api.com is more reliable for free tier
        locXhr.open("GET", "http://ip-api.com/json/")
        locXhr.onreadystatechange = function() {
            if (locXhr.readyState === XMLHttpRequest.DONE) {
                if (locXhr.status === 200) {
                    try {
                        var loc = JSON.parse(locXhr.responseText)
                        if (loc.status === "success") {
                            root.city = loc.city
                            fetchWeather(loc.lat, loc.lon)
                        } else {
                            console.error("[WeatherService] Geo error:", loc.message)
                            fetchWeather(52.52, 13.41)
                        }
                    } catch(e) {
                        console.error("[WeatherService] Location parse error:", e)
                        fetchWeather(52.52, 13.41)
                    }
                } else {
                    console.error("[WeatherService] Geo API status:", locXhr.status)
                    fetchWeather(52.52, 13.41)
                }
            }
        }
        locXhr.send()
    }

    function fetchWeather(lat, lon) {
        console.log("[WeatherService] Fetching weather for " + lat + ", " + lon)
        var xhr = new XMLHttpRequest()
        // Using MET Norway API - Extremely reliable and free
        var url = "https://api.met.no/weatherapi/locationforecast/2.0/compact?lat=" + lat.toFixed(4) + "&lon=" + lon.toFixed(4)
        xhr.open("GET", url)
        // MET Norway requires a unique User-Agent
        xhr.setRequestHeader("User-Agent", "QuickshellWeatherWidget/1.0 (https://github.com/quickshell-mirror/quickshell)")
        
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var json = JSON.parse(xhr.responseText)
                        var current = json.properties.timeseries[0].data.instant.details
                        var symbol = json.properties.timeseries[0].data.next_1_hours.summary.symbol_code
                        
                        root.temp = Math.round(current.air_temperature) + "°C"
                        root.description = symbol.replace(/_/g, " ").toUpperCase()
                        root.humidity = Math.round(current.relative_humidity)
                        root.windSpeed = current.wind_speed
                        
                        root.icon = getWeatherIcon(symbol)
                        console.log("[WeatherService] Weather update success: " + root.temp)
                    } catch(e) {
                        console.error("[WeatherService] Weather parse error:", e)
                    }
                } else {
                    console.error("[WeatherService] Weather API error: " + xhr.status)
                    // If MET Norway fails (429/etc), fallback to Open-Meteo as secondary
                    fetchFallbackWeather(lat, lon)
                }
            }
        }
        xhr.send()
    }

    function fetchFallbackWeather(lat, lon) {
        var xhr = new XMLHttpRequest()
        var url = "https://api.open-meteo.com/v1/forecast?latitude=" + lat + "&longitude=" + lon + "&current=temperature_2m,relative_humidity_2m,weather_code&timezone=auto"
        xhr.open("GET", url)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    var json = JSON.parse(xhr.responseText)
                    root.temp = Math.round(json.current.temperature_2m) + "°C"
                    root.icon = "󰖐"
                } catch(e) {}
            }
        }
        xhr.send()
    }

    function getWeatherIcon(symbol) {
        // Mapping MET Norway symbols to Nerd Font icons
        if (symbol.includes("clearsky")) return "󰖙"
        if (symbol.includes("fair") || symbol.includes("partlycloudy")) return "󰖕"
        if (symbol.includes("cloudy")) return "󰖐"
        if (symbol.includes("rain")) return "󰖖"
        if (symbol.includes("snow")) return "󰖘"
        if (symbol.includes("sleet")) return "󰖘"
        if (symbol.includes("thunder")) return "󰖓"
        if (symbol.includes("fog")) return "󰖑"
        return "󰖐"
    }

    Timer { interval: 1800000; running: true; repeat: true; onTriggered: update() }
}
