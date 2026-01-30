#!/bin/bash

# Check if the rewind utility is already running
PID=$(pgrep -f "quickshell -c rewind")

if [ -n "$PID" ]; then
    # It is running, kill it
    kill $PID
else
    # It is not running, start it
    quickshell -c rewind > /dev/null 2>&1 &
    disown
fi
