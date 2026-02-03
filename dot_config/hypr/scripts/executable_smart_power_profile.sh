#!/bin/bash

# Smart power profile adjustment based on temperature
# Only runs when temperature changes significantly

TEMP_THRESHOLD_LOW=60  # °C - switch to Balanced when below this
TEMP_THRESHOLD_HIGH=75 # °C - switch to Performance when above this
HYSTERESIS=5           # Prevent rapid switching
CHECK_INTERVAL=30      # Check every 30 seconds when active
INACTIVE_TIMEOUT=300   # Stop monitoring after 5 minutes of inactivity

# File to store current state
STATE_FILE="/tmp/.smart_power_profile_state"
TEMP_LOG="/tmp/.temp_readings"

# Function to get CPU temperature
get_temp() {
    # Try different methods to get CPU temperature
    if [ -f "/sys/class/thermal/thermal_zone0/temp" ]; then
        # Convert from millidegree Celsius to Celsius
        temp=$(cat /sys/class/thermal/thermal_zone0/temp)
        echo "scale=2; $temp / 1000" | bc 2>/dev/null || echo 0
    elif command -v sensors &> /dev/null; then
        # Use lm_sensors if available
        temp=$(sensors | grep -E "Package|CPU Temp|Tctl" | head -1 | grep -oE '[0-9]+\.[0-9]*' | head -1)
        echo $temp
    else
        # Fallback to 0 if no method works
        echo 0
    fi
}

# Function to get current power profile
get_current_profile() {
    asusctl profile get 2>/dev/null | grep "Active profile:" | cut -d':' -f2 | tr -d ' '
}

# Function to set power profile
set_profile() {
    local profile=$1
    asusctl profile set $profile 2>/dev/null
}

# Main monitoring loop
main_loop() {
    local last_action_time=$(date +%s)
    
    while true; do
        current_temp=$(get_temp)
        current_profile=$(get_current_profile)
        
        # Determine target profile based on temperature
        target_profile=""
        if (( $(echo "$current_temp < $TEMP_THRESHOLD_LOW" | bc -l) )); then
            target_profile="Balanced"
        elif (( $(echo "$current_temp > $TEMP_THRESHOLD_HIGH" | bc -l) )); then
            target_profile="Performance"
        else
            # Temperature is in middle range, keep current or set to Balanced
            target_profile="Balanced"
        fi
        
        # Apply profile change if needed
        if [ "$target_profile" != "$current_profile" ]; then
            set_profile $target_profile
            last_action_time=$(date +%s)
            
            # Log the change
            echo "$(date): Temp $current_temp°C, Changed profile to $target_profile (was $current_profile)" >> /tmp/power_profile_log
        fi
        
        # Check if we should exit due to inactivity
        current_time=$(date +%s)
        if [ $((current_time - last_action_time)) -gt $INACTIVE_TIMEOUT ]; then
            echo "$(date): Exiting due to inactivity" >> /tmp/power_profile_log
            break
        fi
        
        sleep $CHECK_INTERVAL
    done
}

# Check if another instance is running
if [ -f "$STATE_FILE" ]; then
    pid=$(cat "$STATE_FILE")
    if ps -p $pid > /dev/null; then
        echo "Smart power profile monitor already running with PID $pid"
        exit 0
    fi
fi

# Save current PID
echo $$ > "$STATE_FILE"

# Start monitoring
echo "$(date): Starting smart power profile monitor" >> /tmp/power_profile_log
main_loop

# Cleanup
rm -f "$STATE_FILE"