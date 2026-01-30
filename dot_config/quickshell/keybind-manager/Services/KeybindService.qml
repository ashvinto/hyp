pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var binds: []
    property string configFile: "" // Will be set upon load
    property bool loading: false

    function load() {
        loading = true
        reader.running = true
    }

    function addBinding(mods, key, dispatcher, args) {
        var list = binds.slice() // Copy array
        list.push({
            isNew: true,
            mods: mods,
            key: key,
            dispatcher: dispatcher,
            args: args,
            id: "new_" + Date.now()
        })
        binds = list
    }

    function removeBinding(index) {
        var list = binds.slice()
        if (list[index].isNew) {
            // If it's new and not saved yet, just remove it from array
            list.splice(index, 1)
        } else {
            // Mark for deletion (comment out) on save
            list[index].deleted = true
        }
        binds = list
    }

    function save(newBinds) {
        if (!configFile) return;

        // Construct a shell command to update the file using sed
        // We backup the file first
        var cmd = "cp \"" + configFile + "\" \"" + configFile + ".bak\" && ";
        
        for (var i = 0; i < newBinds.length; i++) {
            var item = newBinds[i];
            
            if (item.deleted) {
                 var lineNum = parseInt(item.id) + 1;
                 // Comment out the line using sed
                 cmd += "sed -i '" + lineNum + "s/^/# /' \"" + configFile + "\" && ";
            } else if (item.isNew) {
                 var newLine = "bind = " + item.mods + ", " + item.key + ", " + item.dispatcher + ", " + item.args;
                 var safeLine = newLine.replace(/'/g, "'\\''");
                 // Append to file
                 cmd += "echo '" + safeLine + "' >> \"" + configFile + "\" && ";
            } else {
                 // Existing item, update it
                 var lineNum = parseInt(item.id) + 1;
                 
                 var newLine = "bind = " + item.mods + ", " + item.key + ", " + item.dispatcher + ", " + item.args;
                 
                 // Escape single quotes for the shell command
                 var safeLine = newLine.replace(/'/g, "'\\''");
                 
                 // Append sed command: sed -i 'Nc new_line' file
                 cmd += "sed -i '" + lineNum + "c " + safeLine + "' \"" + configFile + "\" && ";
            }
        }
        
        // Remove trailing " && " and add success echo
        cmd += "true";

        Quickshell.execDetached(["sh", "-c", cmd]);

        // Reload Hyprland config after a short delay
        reloadTimer.start()
    }

    function restore() {
        if (!configFile) return;
        
        var cmd = "if [ -f \"" + configFile + ".bak\" ]; then cp \"" + configFile + ".bak\" \"" + configFile + "\"; fi";
        
        Quickshell.execDetached(["sh", "-c", cmd]);
        
        // Reload Hyprland config after a short delay
        reloadTimer.start()
    }

    Timer {
        id: reloadTimer
        interval: 1000
        onTriggered: {
            Quickshell.execDetached(["hyprctl", "reload"])
            load() // Refresh UI
        }
    }

    Process {
        id: reader
        // Shell command to find the config file and output its path and content
        // We look for files containing "bind =" to ensure we get the right one.
        command: ["sh", "-c", 
            "candidates=\"$HOME/.config/hypr/configs/keybinds.conf $HOME/.config/hypr/configs/keybinding.conf $HOME/.config/hypr/configs/keybindings.conf $HOME/.config/hypr/configs/*.conf $HOME/.config/hypr/hyprland.conf $HOME/.config/hypr/*.conf\"; for f in $candidates; do if [ -f \"$f\" ] && grep -q \"^bind =\" \"$f\"; then echo \"$f\"; cat \"$f\"; exit 0; fi; done"
        ]
        
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    var lines = text.split('\n');
                    // The first line should be the file path
                    if (lines.length > 0) {
                        var foundPath = lines[0].trim();
                        if (foundPath && foundPath.indexOf('/') !== -1) {
                            root.configFile = foundPath;
                            console.log("[KeybindService] Loaded from:", foundPath);
                            
                            var contentLines = lines.slice(1);
                            var parsedBinds = [];
                            
                            for (var i = 0; i < contentLines.length; i++) {
                                var line = contentLines[i].trim();
                                if (line.startsWith('bind =')) {
                                    // Remove 'bind =' (length 6)
                                    // Handle 'bind =' and 'bind = '
                                    // We split by comma
                                    var rest = line.substring(6);
                                    var parts = rest.split(',').map(function(s) { return s.trim(); });
                                    
                                    if (parts.length >= 3) {
                                        var args = "";
                                        if (parts.length > 3) {
                                            args = parts.slice(3).join(',');
                                        }
                                        
                                        parsedBinds.push({
                                            'id': i.toString(), // Store line index as ID
                                            'mods': parts[0],
                                            'key': parts[1],
                                            'dispatcher': parts[2],
                                            'args': args
                                        });
                                    }
                                }
                            }
                            root.binds = parsedBinds;
                        } else {
                            console.error("[KeybindService] Invalid file path received or no file found");
                        }
                    }
                } else {
                    console.error("[KeybindService] No output from reader process");
                }
                loading = false;
            }
        }
    }
}