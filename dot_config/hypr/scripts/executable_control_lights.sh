#!/bin/bash

SCRIPT_PATH="$HOME/.config/hypr/scripts/keyboard_blink.py"
PNAME="keyboard_blink.py"

case "$1" in
    start)
        if pgrep -f "$PNAME" > /dev/null; then
            notify-send "Keyboard Blink" "Already running."
        else
            nohup "$SCRIPT_PATH" > /dev/null 2>&1 &
            notify-send "Keyboard Blink" "Activated."
        fi
        ;;
    stop)
        if pgrep -f "$PNAME" > /dev/null; then
            pkill -f "$PNAME"
            # Reset to Dim Blue (Idle color) manually since the script might die before resetting
            asusctl aura static -c 000033
            notify-send "Keyboard Blink" "Deactivated."
        else
            notify-send "Keyboard Blink" "Not running."
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
        ;;
esac
