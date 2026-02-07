#!/bin/bash
MANAGER="$HOME/.config/hypr/scripts/shader_man.sh"
STATE_FILE="$HOME/.config/hypr/configs/shader_state.conf"
WARM_MODE=$(grep "WARM_MODE=" "$STATE_FILE" | cut -d= -f2)
if [ "$WARM_MODE" == "on" ]; then
    "$MANAGER" --warm off
    notify-send -u low "Night Light" "Disabled"
else
    "$MANAGER" --warm on
    notify-send -u low "Night Light" "Enabled"
fi
