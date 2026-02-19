#!/bin/bash

# Toggle Retro Mode Shader
FLAG_FILE="/tmp/retro_mode_active"
FOCUS_FLAG="/tmp/focus_mode_active"

if [ -f "$FLAG_FILE" ]; then
    rm "$FLAG_FILE"
    # Re-apply user's saved night light/dimming state
    ~/.config/hypr/scripts/shader_man.sh
    notify-send -u low -i "󰄭" "Retro Mode" "Deactivated"
else
    touch "$FLAG_FILE"
    hyprctl keyword decoration:screen_shader "$HOME/.config/hypr/shaders/retro.frag"
    notify-send -u low -i "󰄭" "Retro Mode" "Activated"
fi
