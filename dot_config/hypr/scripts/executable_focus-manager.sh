#!/bin/bash

# Restricted Shell Manager for Focus Mode
# ONLY manages Bar and Control Center

BAR_CONFIG="bar"
CC_CONFIG="control-center"

BAR_TRIGGER=5
BAR_ACTIVE=450
CC_TRIGGER=10
CC_TIMEOUT=5
BAR_TIMEOUT=2

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

safe_launch() {
    qs -c "$1" & disown
}

update_res

while true; do
    if [ $((SECONDS - last_res_update)) -ge 5 ]; then update_res; fi
    
    running_procs=$(pgrep -af "qs -c")
    [[ "$running_procs" == *"$BAR_CONFIG"* ]] && bar_running=1 || bar_running=0
    [[ "$running_procs" == *"$CC_CONFIG"* ]] && cc_running=1 || cc_running=0

    pos=$(hyprctl cursorpos)
    cx=${pos%,*}
    cy=${pos#*, }
    cy=${cy// /}

    active_ws=$(hyprctl activeworkspace -j)
    [[ "$active_ws" == *'"hasfullscreen": true'* ]] && has_fullscreen="true" || has_fullscreen="false"

    # --- BAR LOGIC ---
    if [ "$cy" -le "$BAR_TRIGGER" ] && [ "$has_fullscreen" = "false" ]; then
        if [ $bar_running -eq 0 ]; then safe_launch $BAR_CONFIG; bar_running=1; fi
        last_bar_active=$SECONDS
    elif [ $bar_running -eq 1 ] && [ "$cy" -le "$BAR_ACTIVE" ] && [ "$has_fullscreen" = "false" ]; then
        last_bar_active=$SECONDS
    fi
    if [ $((SECONDS - last_bar_active)) -ge $BAR_TIMEOUT ] && [ $bar_running -eq 1 ]; then
        pkill -f "qs -c $BAR_CONFIG"; bar_running=0
    fi

    # --- CONTROL CENTER LOGIC ---
    if [ "$cx" -ge "$((sw - CC_TRIGGER))" ] && [ "$cy" -ge "$((sh - CC_TRIGGER))" ] && [ "$has_fullscreen" = "false" ]; then
        if [ $cc_running -eq 0 ]; then safe_launch $CC_CONFIG; cc_running=1; fi
        last_cc_active=$SECONDS
    elif [ $cc_running -eq 1 ] && [ "$cx" -ge "$((sw / 2))" ] && [ "$cy" -ge "$((sh / 2))" ] && [ "$has_fullscreen" = "false" ]; then
        last_cc_active=$SECONDS
    fi
    if [ $((SECONDS - last_cc_active)) -ge $CC_TIMEOUT ] && [ $cc_running -eq 1 ]; then
        pkill -f "qs -c $CC_CONFIG"; cc_running=0
    fi

    sleep 0.1
done
