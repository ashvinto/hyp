#!/bin/bash

# Check if window switcher is already running
if pgrep -f "qs.*window-switcher" > /dev/null; then
    # If it's running, kill it (to simulate selection)
    pkill -f "qs.*window-switcher"
else
    # If not running, start it
    qs -c window-switcher
fi