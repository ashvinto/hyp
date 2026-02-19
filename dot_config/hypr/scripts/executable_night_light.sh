#!/bin/bash
# Fixed Night Light Toggle
MANAGER="$HOME/.config/hypr/scripts/shader_man.sh"
STATE_FILE="$HOME/.config/hypr/configs/shader_state.conf"

# Default to neutral if not found
WARM_VAL=6500
if [ -f "$STATE_FILE" ]; then
    WARM_VAL=$(grep "WARM_VAL=" "$STATE_FILE" | cut -d= -f2)
fi

# Toggle between 4500 (Warm) and 6500 (Neutral)
if [ "$WARM_VAL" -le 5000 ]; then
    "$MANAGER" warm 6500
    notify-send -u low -i "󰖔" "Night Light" "Disabled (6500K)"
else
    "$MANAGER" warm 4500
    notify-send -u low -i "󰖔" "Night Light" "Enabled (4500K)"
fi
