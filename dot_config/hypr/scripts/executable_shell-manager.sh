#!/bin/bash

# Highly Optimized Shell Manager
# Manages Bar, Control Center, and toggles for other components

BAR_CONFIG="bar"
CC_CONFIG="control-center"
MP_CONFIG="music-player"
TB_CONFIG="taskbar"
DB_CONFIG="dashboard"
CB_CONFIG="clipboard"
PM_CONFIG="powermenu"

# Thresholds
BAR_TRIGGER=5
BAR_ACTIVE=450
CC_TRIGGER=10
CC_TIMEOUT=5
BAR_TIMEOUT=2

MP_TRIGGER=10
MP_TIMEOUT=2

PM_TRIGGER=5
PM_TIMEOUT=3

TB_TIMEOUT=3
DB_TRIGGER=5
DB_TIMEOUT=4
CB_TRIGGER=5
CB_TIMEOUT=4

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

update_res() {
    res=$(hyprctl monitors -j | jq -r '.[] | select(.focused==true) | "\(.width) \(.height)"')
    sw=${res% *}
    sh=${res#* }
    last_res_update=$SECONDS
}

sync_state() {
    # Detect manual closures instantly
    if ! pgrep -f "qs -c $BAR_CONFIG" >/dev/null; then bar_running=0; fi
    if ! pgrep -f "qs -c $CC_CONFIG" >/dev/null; then cc_running=0; fi
    if ! pgrep -f "qs -c $MP_CONFIG" >/dev/null; then mp_running=0; fi
    if ! pgrep -f "qs -c $PM_CONFIG" >/dev/null; then pm_running=0; fi
    if ! pgrep -f "qs -c $TB_CONFIG" >/dev/null; then tb_running=0; fi
    if ! pgrep -f "qs -c $DB_CONFIG" >/dev/null; then db_running=0; fi
    if ! pgrep -f "qs -c $CB_CONFIG" >/dev/null; then cb_running=0; fi
}

safe_launch() {
    config=$1
    if ! pgrep -f "qs -c $config" >/dev/null; then
        qs -c "$config" & disown
    fi
}

# 1. Start Bar immediately
safe_launch $BAR_CONFIG
bar_running=1

while true; do
    if [ $((SECONDS - last_res_update)) -ge 5 ]; then update_res; fi
    sync_state

    # Fast Cursor Parsing
    pos=$(hyprctl cursorpos)
    cx=${pos%%,*}
    cx=${cx// /}
    cy=${pos#*, }
    cy=${cy// /}

    # --- BAR LOGIC (Top Edge) ---
    if [ "$cy" -le "$BAR_TRIGGER" ]; then
        if [ $bar_running -eq 0 ]; then safe_launch $BAR_CONFIG; bar_running=1; fi
        last_bar_active=$SECONDS
    elif [ $bar_running -eq 1 ] && [ "$cy" -le "$BAR_ACTIVE" ]; then
        last_bar_active=$SECONDS
    fi
    if [ $((SECONDS - last_bar_active)) -ge $BAR_TIMEOUT ] && [ $bar_running -eq 1 ]; then
        pkill -f "qs -c $BAR_CONFIG"; bar_running=0
    fi

    # --- CONTROL CENTER LOGIC (Bottom Right Corner) ---
    if [ "$cx" -ge "$((sw - CC_TRIGGER))" ] && [ "$cy" -ge "$((sh - CC_TRIGGER))" ]; then
        if [ $cc_running -eq 0 ]; then safe_launch $CC_CONFIG; cc_running=1; fi
        last_cc_active=$SECONDS
    elif [ $cc_running -eq 1 ] && [ "$cx" -ge "$((sw / 2))" ] && [ "$cy" -ge "$((sh / 2))" ]; then
        last_cc_active=$SECONDS
    fi
    if [ $((SECONDS - last_cc_active)) -ge $CC_TIMEOUT ] && [ $cc_running -eq 1 ]; then
        pkill -f "qs -c $CC_CONFIG"; cc_running=0
    fi

    # --- LEFT EDGE SPLIT (Dashboard / Clipboard / Music) ---
    if [ "$cx" -le 5 ]; then
        # 1. Top 40%: Dashboard
        if [ "$cy" -le "$((sh * 4 / 10))" ]; then
            if [ $db_running -eq 0 ]; then safe_launch $DB_CONFIG; db_running=1; fi
            last_db_active=$SECONDS
        # 2. Middle 30%: Clipboard
        elif [ "$cy" -gt "$((sh * 4 / 10))" ] && [ "$cy" -le "$((sh * 7 / 10))" ]; then
            if [ $cb_running -eq 0 ]; then safe_launch $CB_CONFIG; cb_running=1; fi
            last_cb_active=$SECONDS
        # 3. Bottom 30%: Music Player
        elif [ "$cy" -gt "$((sh * 7 / 10))" ]; then
            if [ $mp_running -eq 0 ]; then safe_launch $MP_CONFIG; mp_running=1; fi
            last_mp_active=$SECONDS
        fi
    fi

    # --- MUSIC PLAYER ACTIVE CHECK ---
    if [ $mp_running -eq 1 ] && [ "$cx" -le 400 ] && [ "$cy" -ge "$((sh - 150))" ]; then last_mp_active=$SECONDS; fi
    if [ $((SECONDS - last_mp_active)) -ge $MP_TIMEOUT ] && [ $mp_running -eq 1 ]; then pkill -f "qs -c $MP_CONFIG"; mp_running=0; fi

    # --- CLIPBOARD ACTIVE CHECK ---
    if [ $cb_running -eq 1 ] && [ "$cx" -le 400 ]; then last_cb_active=$SECONDS; fi
    if [ $((SECONDS - last_cb_active)) -ge $CB_TIMEOUT ] && [ $cb_running -eq 1 ]; then pkill -f "qs -c $CB_CONFIG"; cb_running=0; fi

    # --- DASHBOARD ACTIVE CHECK ---
    if [ $db_running -eq 1 ] && [ "$cx" -le 1100 ]; then last_db_active=$SECONDS; fi
    if [ $((SECONDS - last_db_active)) -ge $DB_TIMEOUT ] && [ $db_running -eq 1 ]; then pkill -f "qs -c $DB_CONFIG"; db_running=0; fi

    # --- POWER MENU LOGIC (Right Edge - Top Half) ---
    if [ "$cx" -ge "$((sw - PM_TRIGGER))" ] && [ "$cy" -le "$((sh / 2))" ]; then
        if [ $pm_running -eq 0 ]; then safe_launch $PM_CONFIG; pm_running=1; fi
        last_pm_active=$SECONDS
    elif [ $pm_running -eq 1 ] && [ "$cx" -ge "$((sw - 300))" ]; then
        last_pm_active=$SECONDS
    fi
    if [ $((SECONDS - last_pm_active)) -ge $PM_TIMEOUT ] && [ $pm_running -eq 1 ]; then
        pkill -f "qs -c $PM_CONFIG"; pm_running=0
    fi

    # --- TASKBAR LOGIC (Bottom Edge - Center) ---
    tb_left=$((sw / 4))
    tb_right=$((sw * 3 / 4))
    if [ "$cy" -ge "$((sh - 5))" ] && [ "$cx" -ge "$tb_left" ] && [ "$cx" -le "$tb_right" ]; then
        if [ $tb_running -eq 0 ]; then safe_launch $TB_CONFIG; tb_running=1; fi
        last_tb_active=$SECONDS
    elif [ $tb_running -eq 1 ] && [ "$cy" -ge "$((sh - 100))" ] && [ "$cx" -ge "$tb_left" ] && [ "$cx" -le "$tb_right" ]; then
        last_tb_active=$SECONDS
    fi
    if [ $((SECONDS - last_tb_active)) -ge $TB_TIMEOUT ] && [ $tb_running -eq 1 ]; then
        pkill -f "qs -c $TB_CONFIG"; tb_running=0
    fi

    sleep 0.1
done
