#!/bin/bash

# High-performance Control Center Manager
# Monitors bottom-right corner and manages memory usage

CC_CONFIG="control-center"
CHECK_INTERVAL=0.1
RES_UPDATE_INTERVAL=5
INACTIVITY_TIMEOUT=30

# Cache monitor resolution
update_res() {
    res=$(hyprctl monitors -j | jq -r '.[] | select(.focused==true) | "\(.width) \(.height)"')
    sw=${res% *}
    sh=${res#* }
    last_res_update=$(date +%s)
}

# Initial resolution setup
update_res
last_active=$(date +%s)

while true; do
    now=$(date +%s)
    
    # Update resolution periodically (in case of monitor changes)
    if [ $((now - last_res_update)) -ge $RES_UPDATE_INTERVAL ]; then
        update_res
    fi

    # Fast cursor position parsing (Native bash - no subshells or jq)
    pos=$(hyprctl cursorpos)
    cx=${pos%%,*}
    cx=${cx// /} # Strip spaces
    cy=${pos#*, }
    cy=${cy// /} # Strip spaces

    # 1. Trigger Zone: Start process if cursor hits the absolute 10px corner
    if [ "$cx" -ge "$((sw - 10))" ] && [ "$cy" -ge "$((sh - 10))" ]; then
        if ! pgrep -f "qs -c $CC_CONFIG" > /dev/null; then
            qs -c $CC_CONFIG & disown
        fi
        last_active=$now
    # 2. Activity Zone: Reset timeout if cursor is in bottom-right quadrant while running
    elif pgrep -f "qs -c $CC_CONFIG" > /dev/null; then
        if [ "$cx" -ge "$((sw / 2))" ] && [ "$cy" -ge "$((sh / 2))" ]; then
            last_active=$now
        fi
    fi

    # 3. Memory Cleanup: Kill process after inactivity
    if [ $((now - last_active)) -ge $INACTIVITY_TIMEOUT ]; then
        if pgrep -f "qs -c $CC_CONFIG" > /dev/null; then
            pkill -f "qs -c $CC_CONFIG"
        fi
    fi

    sleep $CHECK_INTERVAL
done
