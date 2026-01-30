#!/bin/bash

while true; do
    # Get Y coordinate
    Y=$(hyprctl cursorpos -j | jq '.y')
    
    if [ "$Y" -le 2 ]; then
        # Check if already running to avoid spam
        if ! pgrep -f "qs -c bar" > /dev/null; then
            qs -c bar &
            # Wait a bit so it doesn't spawn 100 times
            sleep 1
        fi
    fi
    # Poll every 200ms (very low CPU usage)
    sleep 0.2
done
