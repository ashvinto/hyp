#!/bin/bash
# Script to save session before system shutdown/reboot

# Wait a bit to ensure everything is stable
sleep 2

# Save the current session
~/.config/hypr/scripts/session-manager.sh save

echo "Session saved before shutdown"