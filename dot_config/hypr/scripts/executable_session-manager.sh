#!/bin/bash

# Enhanced Session Manager for Hyprland
# Captures and restores applications with their original parameters

SESSION_DIR="$HOME/.config/hypr/session"
SNAPSHOT_FILE="$SESSION_DIR/snapshot.txt"
LOCK_FILE="$SESSION_DIR/restore.lock"
LAST_HASH_FILE="$SESSION_DIR/last_hash.txt"

# Create session directory if it doesn't exist
mkdir -p "$SESSION_DIR"

# Function to get the command that launched an application
get_process_cmdline() {
    local pid=$1
    if [ -n "$pid" ] && [ "$pid" != "null" ]; then
        # Get the command line that started the process
        local cmdline=$(tr '\\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null)
        if [ -n "$cmdline" ]; then
            echo "$cmdline"
            return 0
        fi
    fi
    return 1
}

# Function to save current session
save_session() {
    # Get all clients with their class, workspace, PID, and title
    hyprctl clients -j > "$SESSION_DIR/clients_raw.json"

    # Process each client to get process information
    {
        echo "["
        local first=true
        while IFS= read -r line; do
            local address=$(echo "$line" | jq -r '.address')
            local class=$(echo "$line" | jq -r '.class')
            local title=$(echo "$line" | jq -r '.title')
            local workspace=$(echo "$line" | jq -r '.workspace.id')
            local pid=$(echo "$line" | jq -r '.pid')

            # Get the command line that launched this app
            local cmdline=$(get_process_cmdline "$pid")

            if [ "$first" = true ]; then
                first=false
            else
                echo ","
            fi

            echo "  {"
            echo "    \"address\": \"$address\","
            echo "    \"class\": \"$class\","
            echo "    \"title\": \"$title\","
            echo "    \"workspace\": $workspace,"
            echo "    \"pid\": $pid,"
            echo "    \"cmdline\": \"${cmdline:-}\""
            echo "  }"
        done < <(jq -c '.[]' "$SESSION_DIR/clients_raw.json")
        echo "]"
    } > "$SESSION_DIR/clients_detailed.json"

    # Create a simplified version for the restore process
    > "$SESSION_DIR/clients.txt"  # Clear the file first
    while IFS= read -r line; do
        local workspace=$(echo "$line" | jq -r '.workspace')
        local class=$(echo "$line" | jq -r '.class')
        local title=$(echo "$line" | jq -r '.title')
        local cmdline=$(echo "$line" | jq -r '.cmdline')

        # Extract the main command and arguments
        if [ -n "$cmdline" ] && [ "$cmdline" != "null" ]; then
            # Get the executable name (first part of cmdline)
            local executable=$(echo "$cmdline" | awk '{print $1}' | xargs basename)

            # For some apps, we want to preserve the full command line
            case "$executable" in
                "vivaldi-stable"|"vivaldi"|"vivaldi-bin"|"firefox"|"chromium"|"google-chrome"|"brave")
                    # Extract profile information and other flags
                    local args=$(echo "$cmdline" | sed "s|[^ ]*/$executable||" | xargs)
                    if [ -n "$args" ]; then
                        echo "$workspace $executable $args|$title" >> "$SESSION_DIR/clients.txt"
                    else
                        echo "$workspace $executable $title" >> "$SESSION_DIR/clients.txt"
                    fi
                    ;;
                "code"|"codium")
                    # Extract file/folder paths
                    local args=$(echo "$cmdline" | sed "s|[^ ]*/$executable||" | xargs)
                    if [ -n "$args" ]; then
                        echo "$workspace $executable $args|$title" >> "$SESSION_DIR/clients.txt"
                    else
                        echo "$workspace $executable $title" >> "$SESSION_DIR/clients.txt"
                    fi
                    ;;
                *)
                    # For other apps, just use the executable name
                    echo "$workspace $executable $title" >> "$SESSION_DIR/clients.txt"
                    ;;
            esac
        else
            # Fallback to class if no cmdline available
            echo "$workspace $class $title" >> "$SESSION_DIR/clients.txt"
        fi
    done < <(jq -c '.[]' "$SESSION_DIR/clients_detailed.json")

    # Calculate hash of current session
    current_hash=$(cat "$SESSION_DIR/clients.txt" | md5sum | cut -d' ' -f1)

    # Compare with last saved hash
    if [ -f "$LAST_HASH_FILE" ]; then
        last_hash=$(cat "$LAST_HASH_FILE")
    else
        last_hash=""
    fi

    if [ "$current_hash" != "$last_hash" ]; then
        # Session has changed, update the timestamp
        echo "$current_hash" > "$LAST_HASH_FILE"
        echo "$(date -Iseconds)" > "$SESSION_DIR/timestamp.txt"
        echo "Session updated at $(date)"
    fi
}

# Function to restore session
restore_session() {
    if [ ! -f "$SESSION_DIR/clients.txt" ]; then
        echo "No saved session found."
        return 1
    fi
    
    # Check if lock file exists (prevents multiple restores)
    if [ -f "$LOCK_FILE" ]; then
        echo "Restore already in progress or recently completed."
        return 1
    fi
    
    # Create lock file
    touch "$LOCK_FILE"
    
    echo "Restoring session..."
    
    # Read the saved clients and restore them
    while IFS= read -r line; do
        # Parse the line based on format
        workspace=$(echo "$line" | cut -d' ' -f1)
        class=$(echo "$line" | cut -d' ' -f2)
        
        # Check if this entry has command line arguments (contains |)
        if [[ "$line" == *"|"* ]]; then
            # Format: workspace class args|title
            args_part=$(echo "$line" | cut -d'|' -f1 | cut -d' ' -f3-)
            title=$(echo "$line" | cut -d'|' -f2)
            launch_cmd="$class $args_part"
        else
            # Format: workspace class title
            title=$(echo "$line" | cut -d' ' -f3-)
            launch_cmd="$class"
        fi
        
        if [[ -n "$workspace" && "$workspace" != "null" && -n "$class" && "$class" != "null" ]]; then
            # Switch to target workspace
            hyprctl dispatch workspace "$workspace" >/dev/null 2>&1
            sleep 0.3  # Give time for workspace switch
            
            # Launch the application
            echo "Launching '$launch_cmd' on workspace $workspace"
            eval "$launch_cmd" >/dev/null 2>&1 &
            sleep 1.5  # Delay between app launches
        fi
    done < "$SESSION_DIR/clients.txt"
    
    # Clean up lock file after a delay to prevent rapid restores
    (sleep 30 && rm -f "$LOCK_FILE") &
    
    echo "Session restoration initiated."
}

# Function to show restore notification
show_restore_notification() {
    # Try zenity first as it provides clear yes/no buttons
    if command -v zenity >/dev/null 2>&1; then
        if zenity --question --text="Previous session saved. Restore your workspace layout with all applications?\n\nThis will reopen all apps from your last session on their respective workspaces." --width=300 --height=150 --timeout=20; then
            restore_session
        fi
    elif command -v kdialog >/dev/null 2>&1; then
        # Fallback to kdialog if available
        if kdialog --yesno "Previous session saved. Restore your workspace layout with all applications?\n\nThis will reopen all apps from your last session on their respective workspaces." --title="Session Manager"; then
            restore_session
        fi
    else
        # Fallback to simple notification with instructions
        if command -v notify-send >/dev/null 2>&1; then
            notify-send "Session Manager" \
                "Previous session saved. To restore:\n1. Press Super+Shift+R\nOR\n2. Run: ~/.config/hypr/scripts/session-manager.sh restore" \
                -t 15000 \
                -u normal
        fi
        
        # Also show a simple dialog if any GUI dialog is available
        if command -v xmessage >/dev/null 2>&1; then
            # xmessage works on XWayland, might not work natively on Wayland
            echo "Session available to restore. Run: ~/.config/hypr/scripts/session-manager.sh restore"
        fi
    fi
}

# Handle command line arguments
case "$1" in
    save)
        save_session
        ;;
    restore)
        restore_session
        ;;
    check-and-notify)
        if [ -f "$SESSION_DIR/clients.txt" ]; then
            show_restore_notification
        fi
        ;;
    *)
        echo "Usage: $0 {save|restore|check-and-notify}"
        echo "  save             - Save current session"
        echo "  restore          - Restore last saved session"
        echo "  check-and-notify - Check for saved session and show notification"
        exit 1
        ;;
esac