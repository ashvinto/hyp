#!/bin/bash
LOCK_PATH="/home/zoro/.config/quickshell/lockscreen"

# Prevent multiple instances of the Quickshell lockscreen
if pgrep -f "qs -c $LOCK_PATH" > /dev/null; then
    exit 0
fi

# Launch the Quickshell lockscreen
/usr/bin/qs -c "$LOCK_PATH" & disown
