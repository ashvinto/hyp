#!/bin/bash

# Socket path (handle potential signature variation)
SOCK="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

# Function to check if waybar is currently visible (in layers)
is_waybar_visible() {
    hyprctl layers -j | jq -e '.. | objects | select(.namespace == "waybar")' > /dev/null
}

# Ensure waybar is started
if ! pgrep -x "waybar" > /dev/null; then
    waybar &
    sleep 1
fi

# Main event loop
socat -U - UNIX-CONNECT:"$SOCK" | while read -r line; do
    case "$line" in
        fullscreen\>\>1)
            # Entering fullscreen: If visible, toggle (hide)
            if is_waybar_visible; then
                pkill -SIGUSR1 waybar
            fi
            ;;
        fullscreen\>\>0)
            # Exiting fullscreen: If NOT visible, toggle (show)
            if ! is_waybar_visible; then
                pkill -SIGUSR1 waybar
            fi
            ;;
    esac
done