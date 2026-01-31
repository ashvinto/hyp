#!/bin/bash
CONFIG_PATH="$HOME/.config/quickshell/emoji-picker"

# Check if running
if pgrep -f "qs -c emoji-picker" > /dev/null; then
    pkill -f "qs -c emoji-picker"
else
    # Run
    qs -c emoji-picker & disown
fi
