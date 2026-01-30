pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var emojis: []
    property bool loading: false

    function scan() {
        if (loading || emojis.length > 0) return
        loading = true
        fetcher.running = true
    }

    // Comprehensive emoji list via Python (Fast & reliable)
    Process {
        id: fetcher
        command: ["python3", "-c", `
import json
import unicodedata

emoji_list = []
# Basic range for common emojis
ranges = [
    (0x1F600, 0x1F64F), # Emoticons
    (0x1F300, 0x1F5FF), # Misc Symbols and Pictographs
    (0x1F680, 0x1F6FF), # Transport and Map
    (0x1F900, 0x1F9FF), # Supplemental Symbols and Pictographs
    (0x2600, 0x26FF),   # Misc Symbols
    (0x2700, 0x27BF)    # Dingbats
]

for start, end in ranges:
    for codepoint in range(start, end + 1):
        char = chr(codepoint)
        try:
            name = unicodedata.name(char).lower()
            emoji_list.append({"char": char, "name": name})
        except ValueError:
            continue

print(json.dumps(emoji_list))
`]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) emojis = JSON.parse(text)
                loading = false
            }
        }
    }

    function copy(emoji) {
        Quickshell.execDetached(["sh", "-c", "printf '" + emoji + "' | wl-copy"])
        // Auto close is handled by UI
    }
}
