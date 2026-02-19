#!/bin/bash

# MangoWC optimized shell manager using libinput
# Extremely light on RAM compared to QML triggers

# Configurations
BAR_CONFIG="bar"
DASH_CONFIG="dashboard"
CB_CONFIG="clipboard"
MP_CONFIG="music-player"
PM_CONFIG="powermenu"
TB_CONFIG="taskbar"
CC_CONFIG="control-center"

# Thresholds & Screen (Default 1920x1080 - we'll try to detect)
SW=1920
SH=1080

# Try to get resolution from xdpyinfo or mmsg
if command -v xdpyinfo >/dev/null; then
    res=$(xdpyinfo | grep dimensions | awk '{print $2}')
    SW=${res%x*}
    SH=${res#*x}
fi

# Cursor position tracking
cx=$((SW / 2))
cy=$((SH / 2))

# Launch helper
safe_launch() {
    config=$1
    if ! pgrep -f "qs -n -c $config" >/dev/null; then
        qs -n -c "$config" & disown
    fi
}

# Kill helper
safe_kill() {
    config=$1
    pkill -f "qs -n -c $config"
}

# 1. Start Bar immediately
safe_launch $BAR_CONFIG

# Monitor libinput for pointer motion
# This is much lighter than a QML process
libinput debug-events --pointer | while read -r line; do
    if [[ "$line" == *"POINTER_MOTION"* ]]; then
        # Parse deltas
        dx=$(echo "$line" | grep -oP '(?<= \()[^/]+' | head -n 1)
        dy=$(echo "$line" | grep -oP '(?<=/)[^)]+' | head -n 1)
        
        # Update position with bounds
        cx=$(awk "BEGIN {print int($cx + $dx)}")
        cy=$(awk "BEGIN {print int($cy + $dy)}")
        
        [[ $cx -lt 0 ]] && cx=0
        [[ $cx -gt $SW ]] && cx=$SW
        [[ $cy -lt 0 ]] && cy=0
        [[ $cy -gt $SH ]] && cy=$SH

        # --- TRIGGER LOGIC ---
        
        # Top Edge (Bar)
        if [ "$cy" -le 2 ]; then
            safe_launch $BAR_CONFIG
        fi

        # Left Edge (Dashboard / Clipboard / Music)
        if [ "$cx" -le 2 ]; then
            if [ "$cy" -le "$((SH * 4 / 10))" ]; then
                safe_launch $DASH_CONFIG
            elif [ "$cy" -le "$((SH * 7 / 10))" ]; then
                safe_launch $CB_CONFIG
            else
                safe_launch $MP_CONFIG
            fi
        fi

        # Right Edge (Power Menu)
        if [ "$cx" -ge "$((SW - 2))" ] && [ "$cy" -le "$((SH / 2))" ]; then
            safe_launch $PM_CONFIG
        fi

        # Bottom Edge (Taskbar / Control Center)
        if [ "$cy" -ge "$((SH - 2))" ]; then
            if [ "$cx" -ge "$((SW - 50))" ]; then
                safe_launch $CC_CONFIG
            elif [ "$cx" -ge "$((SW / 4))" ] && [ "$cx" -le "$((SW * 3 / 4))" ]; then
                safe_launch $TB_CONFIG
            fi
        fi
    fi
done
