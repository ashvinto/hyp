#!/bin/bash
LOCK_PATH="$HOME/.config/quickshell/lockscreen"

# Prevent multiple instances of the Quickshell lockscreen
if pgrep -f "qs -c $LOCK_PATH" > /dev/null; then
    exit 0
fi

# Launch the Quickshell lockscreen
qs -c "$LOCK_PATH"

