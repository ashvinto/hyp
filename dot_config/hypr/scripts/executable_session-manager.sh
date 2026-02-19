#!/bin/bash

# Ultra-Robust Session Manager for Hyprland
SESSION_DIR="$HOME/.config/hypr/session"
MAX_HISTORY=10

mkdir -p "$SESSION_DIR"

# Helper to find the "Real" command line of a window
get_true_cmdline() {
    local pid=$1
    if [[ -z "$pid" || "$pid" == "null" ]]; then return; fi
    local cmd=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null)
    
    if [[ "$cmd" == *"vivaldi"* || "$cmd" == *"brave"* || "$cmd" == *"chrome"* ]]; then
        local ppid=$(ps -o ppid= -p "$pid" | xargs)
        if [[ -n "$ppid" ]]; then
            local p_cmd=$(tr '\0' ' ' < "/proc/$ppid/cmdline" 2>/dev/null)
            if [[ "$p_cmd" == *"--profile-directory"* ]]; then echo "$p_cmd"; return; fi
        fi
        local proc_name=$(basename "$(echo "$cmd" | awk '{print $1}')")
        pgrep -u "$USER" -f "$proc_name" | while read -r p; do
            local c=$(tr '\0' ' ' < "/proc/$p/cmdline" 2>/dev/null)
            if [[ "$c" == *"--profile-directory"* ]]; then echo "$c"; return; fi
        done
    fi
    echo "$cmd"
}

save_session() {
    local timestamp=$(date +%Y-%m-%d_%H-%M-%S)
    local out_file="$SESSION_DIR/session_$timestamp.json"
    hyprctl clients -j > "$SESSION_DIR/raw.json"
    
    jq -c '.[]' "$SESSION_DIR/raw.json" | while read -r client; do
        address=$(echo "$client" | jq -r '.address')
        class=$(echo "$client" | jq -r '.class')
        workspace=$(echo "$client" | jq -r '.workspace.id')
        pid=$(echo "$client" | jq -r '.pid')
        raw_cmd=$(get_true_cmdline "$pid")
        safe_cmd=$(echo -n "$raw_cmd" | tr -d '[:cntrl:]' | jq -R .)
        echo "{\"address\":\"$address\",\"class\":\"$class\",\"workspace\":$workspace,\"cmdline\":$safe_cmd}" >> "$SESSION_DIR/build.json"
    done
    
    if [ -f "$SESSION_DIR/build.json" ]; then
        cat "$SESSION_DIR/build.json" | jq -s '.' > "$out_file"
        rm "$SESSION_DIR/build.json"
    else
        echo "[]" > "$out_file"
    fi
    rm "$SESSION_DIR/raw.json"
    ln -sf "$out_file" "$SESSION_DIR/latest.json"
    if ls "$SESSION_DIR"/session_*.json >/dev/null 2>&1; then
        ls -t "$SESSION_DIR"/session_*.json | tail -n +$((MAX_HISTORY + 1)) | xargs -r rm
    fi
}

restore_session() {
    local file=${1:-"$SESSION_DIR/latest.json"}
    if [ ! -f "$file" ]; then echo "No session found."; exit 1; fi
    jq -c '.[]' "$file" | while read -r client; do
        workspace=$(echo "$client" | jq -r '.workspace')
        cmdline=$(echo "$client" | jq -r '.cmdline')
        if [[ -n "$cmdline" && "$cmdline" != "null" ]]; then
            hyprctl dispatch workspace "$workspace" >/dev/null 2>&1
            sleep 0.2
            eval "$cmdline" >/dev/null 2>&1 &
            sleep 1.0 
        fi
    done
}

list_sessions() {
    # Construction of JSON using a robust shell loop to ensure valid format
    echo "["
    local first=true
    if ls "$SESSION_DIR"/session_*.json >/dev/null 2>&1; then
        # Iterate over files and print as JSON objects
        for f in $(ls -t "$SESSION_DIR"/session_*.json); do
            if [ "$first" = true ]; then first=false; else echo ","; fi
            
            time=$(basename "$f" | sed 's/session_//; s/.json//; s/_/ /')
            count=$(jq '. | length' "$f")
            apps=$(jq -r '[.[] | .class] | unique | join(", ")' "$f")
            
            # Use jq to build the object to ensure perfect escaping
            jq -n \
                --arg path "$f" \
                --arg time "$time" \
                --arg count "$count" \
                --arg apps "$apps" \
                '{path: $path, time: $time, appCount: ($count|tonumber), apps: $apps}'
        done
    fi
    echo "]"
}

case "$1" in
    save) save_session ;;
    restore) restore_session "$2" ;;
    list) list_sessions ;;
esac
