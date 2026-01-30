#!/bin/bash

# Auto-hiding bar script
# Monitors cursor position and starts/stops the bar accordingly

BAR_CONFIG="bar"
CHECK_INTERVAL=0.1  # Check every 100ms
TRIGGER_MARGIN=5    # Pixels from top to START the bar
ACTIVE_MARGIN=450   # Pixels from top to KEEP the bar alive (Bar + WiFi Menu)
INACTIVITY_TIMEOUT=2 # Seconds of inactivity before hiding bar

# Function to start the bar
start_bar() {
    if ! pgrep -f "qs -c $BAR_CONFIG" > /dev/null; then
        qs -c $BAR_CONFIG & disown
    fi
}

# Function to stop the bar
stop_bar() {
    if pgrep -f "qs -c $BAR_CONFIG" > /dev/null; then
        pkill -f "qs -c $BAR_CONFIG"
    fi
}

last_active=$(date +%s)

# Main loop
while true; do
    # Get current cursor position
    cursor_y=$(hyprctl cursorpos -j | jq -r '.y')

    if [ "$cursor_y" -le "$TRIGGER_MARGIN" ]; then
        # Cursor is at the very top - trigger start
        start_bar
        last_active=$(date +%s)
    elif pgrep -f "qs -c $BAR_CONFIG" > /dev/null && [ "$cursor_y" -le "$ACTIVE_MARGIN" ]; then
        # Bar is running and cursor is over the bar or menu area - keep alive
        last_active=$(date +%s)
    fi

    # Check for timeout
    current_time=$(date +%s)
    if [ $((current_time - last_active)) -ge "$INACTIVITY_TIMEOUT" ]; then
        stop_bar
    fi

    sleep $CHECK_INTERVAL
done