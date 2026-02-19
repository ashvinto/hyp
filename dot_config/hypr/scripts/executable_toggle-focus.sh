#!/bin/bash

# Enhanced Focus Mode Toggle (Dunst Edition)
FLAG_FILE="/tmp/focus_mode_active"
SHELL_MANAGER="$HOME/.config/hypr/scripts/shell-manager.sh"
FOCUS_MANAGER="$HOME/.config/hypr/scripts/focus-manager.sh"

if [ -f "$FLAG_FILE" ]; then
    # --- DEACTIVATING FOCUS MODE ---
    pkill -f "focus-manager.sh"
    rm "$FLAG_FILE"
    
    # Restore normal shell
    "$SHELL_MANAGER" &
    
    # Disable DND (Dunst)
    dunstctl set-paused false
    
    # Restore power profile to balanced
    powerprofilesctl set balanced 2>/dev/null
    
    # Restore user's saved night light/dimming state
    ~/.config/hypr/scripts/shader_man.sh
    
    notify-send -u low -i "󰈈" "Focus Mode" "Deactivated - Settings restored"
else
    # --- ACTIVATING FOCUS MODE ---
    pkill -f "shell-manager.sh"
    touch "$FLAG_FILE"
    
    # Start restricted shell
    "$FOCUS_MANAGER" &
    
    # Enable DND (Dunst)
    dunstctl set-paused true
    
    # Set power saving
    powerprofilesctl set power-saver 2>/dev/null

    # Apply grayscale shader for visual focus
    hyprctl keyword decoration:screen_shader "$HOME/.config/hypr/shaders/grayscale.frag"
    
    notify-send -u critical -i "󰈉" "Focus Mode" "Activated - DND enabled & Power-save on"
fi
