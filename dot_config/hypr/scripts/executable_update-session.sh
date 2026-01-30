#!/bin/bash

# Session updater script - runs periodically to keep session file current

# Update the session file
~/.config/hypr/scripts/session-manager.sh save

# Optionally, we could add logic to detect if system is shutting down
# and perform a final save, but for now we'll just update periodically