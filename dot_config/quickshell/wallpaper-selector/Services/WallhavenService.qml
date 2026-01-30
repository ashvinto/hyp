pragma Singleton
import QtQuick
import Quickshell
import "."

Singleton {
    id: root
    property var results: []
    property bool loading: false
    property string lastError: ""
    property int currentPage: 1
    property int lastPage: 1
    property string currentQuery: ""

    // Search parameters
    property string sorting: "relevance" // relevance, random, date_added, views, favorites, toplist
    property string topRange: "1M" // 1d, 3d, 1w, 1M, 3M, 6M, 1y
    property string purity: "111" // 100=sfw, 110=sfw/sketchy, 111=sfw/sketchy/nsfw
    property string categories: "111" // general/anime/people

    function search(query, page) {
        if (loading) return
        loading = true
        results = []
        lastError = ""
        currentQuery = query || ""
        currentPage = page || 1

        var params = []
        
        // If sorting is relevance but no query, switch to date_added to show latest wallpapers
        var effectiveSorting = sorting
        if (effectiveSorting === "relevance" && (!currentQuery || currentQuery.trim() === "")) {
            effectiveSorting = "date_added"
        }

        if (currentQuery && currentQuery.trim() !== "") {
            params.push("q=" + encodeURIComponent(currentQuery))
        }
        
        params.push("page=" + currentPage)
        params.push("sorting=" + effectiveSorting)
        params.push("purity=" + purity)
        params.push("categories=" + categories)
        
        if (effectiveSorting === "toplist") {
            params.push("topRange=" + topRange)
        }

        if (AppConfig.wallhavenApiKey) {
            params.push("apikey=" + AppConfig.wallhavenApiKey)
        }

        var url = "https://wallhaven.cc/api/v1/search?" + params.join("&")

        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                loading = false
                if (xhr.status === 200) {
                    try {
                        var json = JSON.parse(xhr.responseText)
                        results = json.data
                        if (json.meta) {
                            lastPage = json.meta.last_page
                        }
                    } catch (e) {
                        lastError = "Failed to parse response"
                    }
                } else {
                    lastError = "HTTP Error: " + xhr.status
                }
            }
        }
        xhr.open("GET", url)
        xhr.send()
    }

    function nextPage() {
        if (currentPage < lastPage) {
            search(currentQuery, currentPage + 1)
        }
    }

    function prevPage() {
        if (currentPage > 1) {
            search(currentQuery, currentPage - 1)
        }
    }

    function download(url, id, callback) {
        var ext = url.split('.').pop()
        var dest = AppConfig.wallpaperDir + "/wallhaven_" + id + "." + ext
        
        var proc = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ["curl", "-s", "-o", "${dest}", "${url}"]
            }
        `, root, "dl_" + id)
        
        proc.exited.connect(function(code) {
            if (code === 0) {
                // Rotation logic:
                // 1. Delete second-last wallpaper if exists
                if (AppConfig.prevWallpaperPath !== "" && AppConfig.prevWallpaperPath !== dest) {
                    var delProc = Qt.createQmlObject(`
                        import Quickshell.Io
                        Process {
                            command: ["rm", "-f", "${AppConfig.prevWallpaperPath}"]
                        }
                    `, root, "del_" + Date.now())
                    delProc.running = true
                }

                // 2. Shift last to previous
                AppConfig.prevWallpaperPath = AppConfig.lastWallpaperPath
                
                // 3. Update last to current
                AppConfig.lastWallpaperPath = dest

                if (callback) callback(dest)
            }
            proc.destroy()
        })
        proc.running = true
    }
}