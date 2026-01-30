#!/bin/bash

# Check dependencies
for cmd in cliphist wofi wl-copy wl-paste notify-send; do
    if ! command -v $cmd &>/dev/null; then
        notify-send "Error" "$cmd is not installed"
        exit 1
    fi
done

# Get history
selected=$(cliphist list | rofi -dmenu -p "Clipboard History")

[ -z "$selected" ] && exit 0

# Decode selected item
decoded=$(echo "$selected" | cliphist decode)

# Copy to clipboard
echo -n "$decoded" | wl-copy

notify-send "Clipboard Manager" "Copied to clipboard"
