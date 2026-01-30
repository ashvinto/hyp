#!/bin/bash
CONFIG_PATH="$HOME/.config/quickshell/launcher"

# Check if running
if pgrep -f "qs -c launcher" > /dev/null; then
    pkill -f "qs -c launcher"
else
    # Run
    qs -c launcher & disown
fi
