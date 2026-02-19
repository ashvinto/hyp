#!/bin/bash

# Optimized Shell Manager with Precise Process Matching
BAR_CONFIG="bar"
CC_CONFIG="control-center"
MP_CONFIG="music-player"
TB_CONFIG="taskbar"
DB_CONFIG="dashboard"
CB_CONFIG="clipboard"
PM_CONFIG="powermenu"

# Thresholds & Timeouts
BAR_TRIGGER=5
BAR_ACTIVE=450
BAR_TIMEOUT=3

CC_TRIGGER=10
CC_TIMEOUT=6

MP_TRIGGER=10
MP_TIMEOUT=5

PM_TRIGGER=5
PM_TIMEOUT=5

TB_TIMEOUT=5
DB_TRIGGER=5
DB_TIMEOUT=8
CB_TRIGGER=5
CB_TIMEOUT=8

# State tracking
bar_running=0
cc_running=0
mp_running=0
pm_running=0
tb_running=0
db_running=0
cb_running=0

last_bar_active=$SECONDS
last_cc_active=$SECONDS
last_mp_active=$SECONDS
last_pm_active=$SECONDS
last_tb_active=$SECONDS
last_db_active=$SECONDS
last_cb_active=$SECONDS
last_res_update=-10
last_ws_check=-10

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
    
    # Precise pgrep to avoid matching "bar" in "taskbar"
    running_procs=$(pgrep -af "qs -c")
    
    # Precise state sync
    update_state() {
        local name=$1; local current_var=$2; local last_active_var=$3
        # Match "qs -c name" exactly at the end of the line or followed by space
        if echo "$running_procs" | grep -qE "qs -c +$name($|[[:space:]])"; then
            if [ "${!current_var}" -eq 0 ]; then eval "$last_active_var=$SECONDS"; fi
            eval "$current_var=1"
        else
            eval "$current_var=0"
        fi
    }

    update_state "$BAR_CONFIG" bar_running last_bar_active
    update_state "$CC_CONFIG" cc_running last_cc_active
    update_state "$MP_CONFIG" mp_running last_mp_active
    update_state "$PM_CONFIG" pm_running last_pm_active
    update_state "$TB_CONFIG" tb_running last_tb_active
    update_state "$DB_CONFIG" db_running last_db_active
    update_state "$CB_CONFIG" cb_running last_cb_active

    pos=$(hyprctl cursorpos)
    cx=${pos%,*}; cy=${pos#*, }; cy=${cy// /}

    if [ $((SECONDS - last_ws_check)) -ge 1 ]; then
        active_ws=$(hyprctl activeworkspace -j)
        [[ "$active_ws" == *'"hasfullscreen": true'* ]] && has_fullscreen="true" || has_fullscreen="false"
        last_ws_check=$SECONDS
    fi

    # --- 3. BAR LOGIC ---
    if [ "$cy" -le "$BAR_TRIGGER" ] && [ "$has_fullscreen" = "false" ]; then
        if [ $bar_running -eq 0 ]; then safe_launch $BAR_CONFIG; fi
        last_bar_active=$SECONDS
    elif [ $bar_running -eq 1 ] && [ "$cy" -le "$BAR_ACTIVE" ]; then
        last_bar_active=$SECONDS
    fi
    if [ $((SECONDS - last_bar_active)) -ge $BAR_TIMEOUT ] && [ $bar_running -eq 1 ]; then
        pkill -f "qs -c $BAR_CONFIG$" || pkill -f "qs -c $BAR_CONFIG "
    fi

    # --- 4. CONTROL CENTER LOGIC ---
    if [ "$cx" -ge "$((sw - CC_TRIGGER))" ] && [ "$cy" -ge "$((sh - CC_TRIGGER))" ] && [ "$has_fullscreen" = "false" ]; then
        if [ $cc_running -eq 0 ]; then safe_launch $CC_CONFIG; fi
        last_cc_active=$SECONDS
    elif [ $cc_running -eq 1 ] && [ "$cx" -ge "$((sw / 2))" ] && [ "$cy" -ge "$((sh / 2))" ]; then
        last_cc_active=$SECONDS
    fi
    if [ $((SECONDS - last_cc_active)) -ge $CC_TIMEOUT ] && [ $cc_running -eq 1 ]; then
        pkill -f "qs -c $CC_CONFIG$" || pkill -f "qs -c $CC_CONFIG "
    fi

    # --- 5. LEFT EDGE SPLIT ---
    if [ "$cx" -le 5 ] && [ "$has_fullscreen" = "false" ]; then
        if [ "$cy" -le "$((sh * 4 / 10))" ]; then
            if [ $db_running -eq 0 ]; then safe_launch $DB_CONFIG; fi
            last_db_active=$SECONDS
        elif [ "$cy" -gt "$((sh * 4 / 10))" ] && [ "$cy" -le "$((sh * 7 / 10))" ]; then
            if [ $cb_running -eq 0 ]; then safe_launch $CB_CONFIG; fi
            last_cb_active=$SECONDS
        elif [ "$cy" -gt "$((sh * 7 / 10))" ]; then
            if [ $mp_running -eq 0 ]; then safe_launch $MP_CONFIG; fi
            last_mp_active=$SECONDS
        fi
    fi

    # --- 6. ACTIVE CHECKS ---
    if [ $mp_running -eq 1 ] && [ "$cx" -le 450 ] && [ "$cy" -ge "$((sh - 250))" ]; then last_mp_active=$SECONDS; fi
    if [ $((SECONDS - last_mp_active)) -ge $MP_TIMEOUT ] && [ $mp_running -eq 1 ]; then pkill -f "qs -c $MP_CONFIG"; fi

    if [ $cb_running -eq 1 ] && [ "$cx" -le 450 ]; then last_cb_active=$SECONDS; fi
    if [ $((SECONDS - last_cb_active)) -ge $CB_TIMEOUT ] && [ $cb_running -eq 1 ]; then pkill -f "qs -c $CB_CONFIG"; fi

    if [ $db_running -eq 1 ] && [ "$cx" -le 1100 ]; then last_db_active=$SECONDS; fi
    if [ $((SECONDS - last_db_active)) -ge $DB_TIMEOUT ] && [ $db_running -eq 1 ]; then pkill -f "qs -c $DB_CONFIG"; fi

    # --- 7. POWER MENU LOGIC ---
    # Trigger: Top 25% of right edge
    if [ "$cx" -ge "$((sw - PM_TRIGGER))" ] && [ "$cy" -le "$((sh / 4))" ] && [ "$has_fullscreen" = "false" ]; then
        if [ $pm_running -eq 0 ]; then safe_launch $PM_CONFIG; fi
        last_pm_active=$SECONDS
    # Active Area: Large central box for the new centered menu
    elif [ $pm_running -eq 1 ] && [ "$cx" -ge "$((sw/2 - 400))" ] && [ "$cx" -le "$((sw/2 + 400))" ] && [ "$cy" -ge "$((sh/2 - 350))" ] && [ "$cy" -le "$((sh/2 + 350))" ]; then
        last_pm_active=$SECONDS
    fi
    if [ $((SECONDS - last_pm_active)) -ge $PM_TIMEOUT ] && [ $pm_running -eq 1 ]; then
        pkill -f "qs -c $PM_CONFIG$" || pkill -f "qs -c $PM_CONFIG "
    fi

    # --- 8. TASKBAR LOGIC ---
    tb_left=$((sw / 4)); tb_right=$((sw * 3 / 4))
    if [ "$cy" -ge "$((sh - 5))" ] && [ "$cx" -ge "$tb_left" ] && [ "$cx" -le "$tb_right" ] && [ "$has_fullscreen" = "false" ]; then
        if [ $tb_running -eq 0 ]; then safe_launch $TB_CONFIG; fi
        last_tb_active=$SECONDS
    elif [ $tb_running -eq 1 ] && [ "$cy" -ge "$((sh - 120))" ]; then
        last_tb_active=$SECONDS
    fi
    if [ $((SECONDS - last_tb_active)) -ge $TB_TIMEOUT ] && [ $tb_running -eq 1 ]; then
        pkill -f "qs -c $TB_CONFIG$" || pkill -f "qs -c $TB_CONFIG "
    fi

    sleep 0.3
done
