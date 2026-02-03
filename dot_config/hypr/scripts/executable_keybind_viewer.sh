#!/bin/bash
CONFIG_PATH="$HOME/.config/quickshell/launcher"

# Check if running
if pgrep -f "qs -c keybind-viewer" >/dev/null; then
  pkill -f "qs -c keybind-viewer"
else
  # Run
  qs -c keybind-viewer &
  disown
fi
