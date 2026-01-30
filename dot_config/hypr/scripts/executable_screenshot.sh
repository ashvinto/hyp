#!/bin/bash

# Configuration
TMP_FILE="/tmp/qs_screenshot_edit.png"

# Function to run swappy
open_swappy() {
    swappy -f "$TMP_FILE"
}

# Handle Arguments
case "$1" in
    "area")
        grim -g "$(slurp)" "$TMP_FILE" && open_swappy
        ;;
    "full")
        grim "$TMP_FILE" && open_swappy
        ;;
    "window")
        grim -g "$(slurp)" "$TMP_FILE" && open_swappy
        ;;
    "freeze")
        # For freeze, we still use Quickshell for the initial freeze/crop UI, 
        # but then pass to swappy.
        grim /tmp/qs_freeze.png
        QS_SCREENSHOT_MODE=overlay qs -c screenshot & disown
        ;;
    *)
        # No arg: Open Panel
        if pgrep -f "qs -c screenshot" > /dev/null; then
            pkill -f "qs -c screenshot"
        else
            qs -c screenshot & disown
        fi
        ;;
esac