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
    
    # Surgical restore instead of full reload to preserve manual settings
    CONFIG_FILE="$HOME/.config/quickshell/config.json"
    ROUNDING=$(jq -r '.hyprRounding // 12' "$CONFIG_FILE")
    GAPS_IN=$(jq -r '.hyprGapsIn // 5' "$CONFIG_FILE")
    GAPS_OUT=$(jq -r '.hyprGapsOut // 10' "$CONFIG_FILE")
    BLUR=$(jq -r '.hyprBlur // true' "$CONFIG_FILE")
    SHADOWS=$(jq -r '.hyprShadows // true' "$CONFIG_FILE")
    
    [ "$BLUR" = "true" ] && BLUR_VAL=1 || BLUR_VAL=0
    [ "$SHADOWS" = "true" ] && SHADOW_VAL=1 || SHADOW_VAL=0

    hyprctl --batch "
        keyword animations:enabled 1;
        keyword decoration:drop_shadow $SHADOW_VAL;
        keyword decoration:blur:enabled $BLUR_VAL;
        keyword general:gaps_in $GAPS_IN;
        keyword general:gaps_out $GAPS_OUT;
        keyword decoration:rounding $ROUNDING"
        
    # Also restore shader state
    ~/.config/hypr/scripts/shader_man.sh
    
    notify-send -u low "Zen Mode" "Deactivated - Settings Restored"
fi
