#!/bin/bash

ASSET_DIR="$HOME/.config/quickshell/dashboard/assets"
TARGET_FILE="$ASSET_DIR/profile.png"

mkdir -p "$ASSET_DIR"

INPUT="$1"

# If no input provided, try to open a file picker
if [ -z "$INPUT" ]; then
    if command -v zenity &> /dev/null; then
        INPUT=$(zenity --file-selection --title="Select Profile Picture" --file-filter="Images | *.jpg *.jpeg *.png *.gif" 2>/dev/null)
    elif command -v kdialog &> /dev/null; then
        INPUT=$(kdialog --getopenfilename . "Images (*.jpg *.jpeg *.png *.gif)")
    fi
fi

if [ -z "$INPUT" ]; then
    exit 1
fi

# Normalize paths for comparison
REAL_INPUT=$(realpath "$INPUT")
REAL_TARGET=$(realpath "$TARGET_FILE")

# Force update: remove target first
if [ -f "$TARGET_FILE" ] && [ "$REAL_INPUT" != "$REAL_TARGET" ]; then
    rm "$TARGET_FILE"
fi

if [[ "$INPUT" =~ ^http.* ]]; then
    # Download to temp file first
    TEMP_FILE="/tmp/profile_temp_$(date +%s)"
    curl -L "$INPUT" -o "$TEMP_FILE"
    ffmpeg -y -i "$TEMP_FILE" "$TARGET_FILE" 2>/dev/null
    rm "$TEMP_FILE"
elif [ -f "$INPUT" ]; then
    # Use ffmpeg to convert/copy to ensure it's a valid PNG
    ffmpeg -y -i "$INPUT" "$TARGET_FILE" 2>/dev/null
else
    echo "Invalid input."
    exit 1
fi

notify-send "Dashboard" "Profile picture updated! Reopen dashboard to see changes."
