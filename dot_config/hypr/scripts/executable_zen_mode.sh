#!/bin/bash
# Smart Zen Mode
HYPR_ANIMATIONS=$(hyprctl getoption animations:enabled | grep "int:" | awk '{print $2}')

if [ "$HYPR_ANIMATIONS" -eq 1 ]; then
    BAT_STATUS=$(cat /sys/class/power_supply/BAT*/status | head -n1)
    if [ "$BAT_STATUS" = "Discharging" ]; then
        powerprofilesctl set power-saver 2>/dev/null
        brightnessctl set 30%
        NOTIF_MSG="Zen Mode: Battery Optimized"
    else
        powerprofilesctl set balanced 2>/dev/null
        NOTIF_MSG="Zen Mode: Performance Boost"
    fi
    hyprctl --batch "
        keyword animations:enabled 0;
        keyword decoration:shadow:enabled 0;
        keyword decoration:blur:enabled 0;
        keyword general:gaps_in 0;
        keyword general:gaps_out 0;
        keyword decoration:rounding 0"
    notify-send -u low "Zen Mode" "$NOTIF_MSG"
else
    powerprofilesctl set balanced 2>/dev/null
    hyprctl reload
    notify-send -u low "Zen Mode" "Deactivated"
fi
