#!/bin/bash

# Highly Optimized Shell Manager
# Manages Bar, Control Center, and toggles for other components

BAR_CONFIG="bar"
CC_CONFIG="control-center"

# Thresholds
BAR_TRIGGER=5
BAR_ACTIVE=450
CC_TRIGGER=10
CC_TIMEOUT=5
BAR_TIMEOUT=2

# State tracking
bar_running=0
cc_running=0
last_bar_active=$SECONDS
last_cc_active=$SECONDS
last_res_update=-10

update_res() {
    res=$(hyprctl monitors -j | jq -r '.[] | select(.focused==true) | "\(.width) \(.height)"')
    sw=${res% *}
    sh=${res#* }
    last_res_update=$SECONDS
}

# 1. Start Bar immediately (process caching)
if ! pgrep -f "qs -c $BAR_CONFIG" > /dev/null; then
    qs -c $BAR_CONFIG & disown
    bar_running=1
fi

while true; do
    # Check for resolution updates
    if [ $((SECONDS - last_res_update)) -ge 5 ]; then
        update_res
    fi

    # Fast Cursor Parsing
    pos=$(hyprctl cursorpos)
    cx=${pos%%,*}
    cx=${cx// /}
    cy=${pos#*, }
    cy=${cy// /}

    # --- BAR LOGIC ---
    if [ "$cy" -le "$BAR_TRIGGER" ]; then
        if [ $bar_running -eq 0 ]; then
            if ! pgrep -f "qs -c $BAR_CONFIG" > /dev/null; then
                qs -c $BAR_CONFIG & disown
            fi
            bar_running=1
        fi
        last_bar_active=$SECONDS
    elif [ $bar_running -eq 1 ] && [ "$cy" -le "$BAR_ACTIVE" ]; then
        last_bar_active=$SECONDS
    fi

    if [ $((SECONDS - last_bar_active)) -ge $BAR_TIMEOUT ] && [ $bar_running -eq 1 ]; then
        pkill -f "qs -c $BAR_CONFIG"
        bar_running=0
    fi

    # --- CONTROL CENTER LOGIC ---
    if [ "$cx" -ge "$((sw - CC_TRIGGER))" ] && [ "$cy" -ge "$((sh - CC_TRIGGER))" ]; then
        if [ $cc_running -eq 0 ]; then
            if ! pgrep -f "qs -c $CC_CONFIG" > /dev/null; then
                qs -c $CC_CONFIG & disown
            fi
            cc_running=1
        fi
        last_cc_active=$SECONDS
    elif [ $cc_running -eq 1 ] && [ "$cx" -ge "$((sw / 2))" ] && [ "$cy" -ge "$((sh / 2))" ]; then
        last_cc_active=$SECONDS
    fi

    if [ $((SECONDS - last_cc_active)) -ge $CC_TIMEOUT ] && [ $cc_running -eq 1 ]; then
        pkill -f "qs -c $CC_CONFIG"
        cc_running=0
    fi

    sleep 0.1
done
