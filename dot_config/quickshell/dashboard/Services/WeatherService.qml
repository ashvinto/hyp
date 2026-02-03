pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    // Configuration Properties (Hardcoded defaults for now, can be exposed later)
    property string configLocation: "" // "lat,lon" or "City Name"
    property bool useFahrenheit: false
    property bool useTwelveHourClock: false

    property string city: "Locating..."
    property string loc: ""
    property var cc: null
    property list<var> forecast: []
    property list<var> hourlyForecast: []

    // Read-only properties for UI binding
    readonly property string icon: cc ? getWeatherIcon(cc.weatherCode) : "cloud_off" // Simplified icon mapping
    readonly property string description: cc?.weatherDesc ?? "No Data"
    readonly property string temp: useFahrenheit ? `${cc?.tempF ?? 0}°F` : `${cc?.tempC ?? 0}°C`
    readonly property string feelsLike: useFahrenheit ? `${cc?.feelsLikeF ?? 0}°F` : `${cc?.feelsLikeC ?? 0}°C`
    readonly property int humidity: cc?.humidity ?? 0
    readonly property real windSpeed: cc?.windSpeed ?? 0
    
    // Internal Cache
    property var cachedCities: ({})

    Component.onCompleted: reload()

    function reload() {
        if (configLocation) {
            if (configLocation.indexOf(",") !== -1 && !isNaN(parseFloat(configLocation.split(",")[0]))) {
                loc = configLocation
                fetchCityFromCoords(configLocation)
            } else {
                fetchCoordsFromCity(configLocation)
            }
        } else if (!loc) {
            // Auto-detect location via IP
            var xhr = new XMLHttpRequest()
            xhr.open("GET", "https://ipinfo.io/json")
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (xhr.status === 200) {
                        var response = JSON.parse(xhr.responseText)
                        if (response.loc) {
                            loc = response.loc
                            city = response.city || "Unknown City"
                            fetchWeatherData()
                        }
                    } 
                }
            }
            xhr.send()
        } else {
             fetchWeatherData()
        }
    }

    function fetchCityFromCoords(coords) {
        if (cachedCities[coords]) {
            city = cachedCities[coords]
            return
        }
        var [lat, lon] = coords.split(",")
        var xhr = new XMLHttpRequest()
        xhr.open("GET", `https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lon}&format=geocodejson`)
        xhr.onreadystatechange = function() {
             if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                var geo = JSON.parse(xhr.responseText).features?.[0]?.properties.geocoding
                if (geo) {
                    var geoCity = geo.type === "city" ? geo.name : geo.city
                    city = geoCity
                    cachedCities[coords] = geoCity
                }
             }
        }
        xhr.send()
    }

    function fetchCoordsFromCity(cityName) {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", `https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(cityName)}&count=1&language=en&format=json`)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                var json = JSON.parse(xhr.responseText)
                if (json.results && json.results.length > 0) {
                    var result = json.results[0]
                    loc = result.latitude + "," + result.longitude
                    city = result.name
                    fetchWeatherData()
                }
            }
        }
        xhr.send()
    }

    function fetchWeatherData() {
        if (!loc || loc.indexOf(",") === -1) return

        var [lat, lon] = loc.split(",")
        var baseUrl = "https://api.open-meteo.com/v1/forecast"
        var params = [
            "latitude=" + lat, 
            "longitude=" + lon, 
            "hourly=weather_code,temperature_2m", 
            "daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset", 
            "current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code,wind_speed_10m", 
            "timezone=auto", 
            "forecast_days=7"
        ]
        var url = baseUrl + "?" + params.join("&")

        var xhr = new XMLHttpRequest()
        xhr.open("GET", url)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                var json = JSON.parse(xhr.responseText)
                if (!json.current || !json.daily) return

                cc = {
                    weatherCode: json.current.weather_code,
                    weatherDesc: getWeatherCondition(json.current.weather_code),
                    tempC: Math.round(json.current.temperature_2m),
                    tempF: Math.round((json.current.temperature_2m * 9 / 5) + 32),
                    feelsLikeC: Math.round(json.current.apparent_temperature),
                    feelsLikeF: Math.round((json.current.apparent_temperature * 9 / 5) + 32),
                    humidity: json.current.relative_humidity_2m,
                    windSpeed: json.current.wind_speed_10m
                }
            }
        }
        xhr.send()
    }

    function getWeatherCondition(code) {
        var conditions = {
            "0": "Clear", "1": "Clear", "2": "Partly cloudy", "3": "Overcast",
            "45": "Fog", "48": "Fog", "51": "Drizzle", "53": "Drizzle", "55": "Drizzle",
            "61": "Light Rain", "63": "Rain", "65": "Heavy Rain", "71": "Light Snow",
            "73": "Snow", "75": "Heavy Snow", "80": "Showers", "95": "Thunderstorm"
        }
        return conditions[code] || "Unknown"
    }
    
    function getWeatherIcon(code) {
        // Simple mapping to Nerd Fonts Weather Icons
        var icons = {
            "0": "󰖙", "1": "󰖙", "2": "󰖕", "3": "󰖐",
            "45": "󰖑", "48": "󰖑", "51": "󰖗", "53": "󰖗", "55": "󰖗",
            "61": "󰖖", "63": "󰖖", "65": "󰖖", "71": "󰼶",
            "73": "󰼶", "75": "󰼶", "80": "󰖖", "95": "󰖓"
        }
        return icons[code] || "󰖐"
    }

    Timer {
        interval: 3600000 // 1 hour refresh
        running: true
        repeat: true
        onTriggered: fetchWeatherData()
    }
}
