#!/bin/bash

# Check if the keybind manager is already running
PID=$(pgrep -f "quickshell -c keybind-manager")

if [ -n "$PID" ]; then
    # It is running, kill it
    kill $PID
else
    # It is not running, start it
    # Run in background and disown to prevent hanging the calling process
    quickshell -c keybind-manager > /dev/null 2>&1 &
    disown
fi
