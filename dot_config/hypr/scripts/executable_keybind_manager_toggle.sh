#!/bin/bash

BINDER_PATH="$HOME/.config/quickshell/keybind-manager"

# Check if the keybind manager is already running
PID=$(pgrep -f "qs -c $BINDER_PATH$")

if [ -n "$PID" ]; then
  # It is running, kill it
  kill $PID
else
  # It is not running, start it
  # Run in background and disown to prevent hanging the calling process
  qs -c $BINDER_PATH >/dev/null 2>&1 &
  disown
fi
