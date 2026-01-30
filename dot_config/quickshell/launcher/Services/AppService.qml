pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var apps: []
    property bool loading: false

    function scan() {
        if (loading) return
        loading = true
        scanner.running = true
    }

    Process {
        id: scanner
        command: ["python3", "-c", `
import os
import json

apps = []
dirs = ["/usr/share/applications", os.path.expanduser("~/.local/share/applications")]

for d in dirs:
    if not os.path.exists(d): continue
    for f in os.scandir(d):
        if not f.name.endswith(".desktop"): continue
        try:
            entry = {}
            with open(f.path, "r", encoding="utf-8", errors="ignore") as file:
                for line in file:
                    if line.startswith("["):
                        if line.strip() == "[Desktop Entry]": continue
                        else: break # Stop at other sections for speed
                    if "=" in line:
                        k, v = line.split("=", 1)
                        entry[k.strip()] = v.strip()
            
            if entry.get("NoDisplay") == "true": continue
            name, icon, exec_cmd = entry.get("Name"), entry.get("Icon"), entry.get("Exec")
            
            if name and exec_cmd:
                categories = entry.get("Categories", "Other").split(";")
                primary_cat = "Other"
                if "WebBrowser" in categories or "Network" in categories: primary_cat = "Internet"
                elif "Development" in categories: primary_cat = "Dev"
                elif "System" in categories: primary_cat = "System"
                elif "Game" in categories: primary_cat = "Games"
                elif "Graphics" in categories: primary_cat = "Graphics"
                elif "Utility" in categories: primary_cat = "Tools"
                
                apps.append({
                    "name": name,
                    "icon": icon or "",
                    "exec": exec_cmd.split("%")[0].strip(),
                    "id": f.name,
                    "category": primary_cat
                })
        except: continue

# Deduplicate by name + exec
unique = { (a["name"], a["exec"]): a for a in apps }
result = sorted(unique.values(), key=lambda x: x["name"].lower())
print(json.dumps(result))
`]
        
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) apps = JSON.parse(text)
                loading = false
            }
        }
    }

    function launch(cmd) {
        Quickshell.execDetached(["sh", "-c", cmd])
        Qt.quit()
    }
}
