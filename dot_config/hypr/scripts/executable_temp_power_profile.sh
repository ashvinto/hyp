#!/bin/bash

# Smart power profile adjustment based on temperature with manual override
# Only runs when temperature changes significantly

# Temperature thresholds
TEMP_THRESHOLD_LOW=60   # °C - switch to Balanced when below this
TEMP_THRESHOLD_HIGH=75  # °C - switch to Performance when above this
CHECK_INTERVAL=30       # Check every 30 seconds when active
OVERRIDE_DURATION=300   # Don't auto-adjust for 5 minutes after manual override

# State file to track manual overrides
STATE_FILE="/tmp/.auto_power_profile_state"

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

# Function to check if we're in override mode
is_override_active() {
    if [ -f "$STATE_FILE" ]; then
        override_until=$(cat "$STATE_FILE")
        current_time=$(date +%s)
        if [ $current_time -lt $override_until ]; then
            return 0  # Override is active
        else
            rm -f "$STATE_FILE"  # Expired, remove the file
            return 1  # Override is not active
        fi
    else
        return 1  # Override is not active
    fi
}

# Function to activate override
activate_override() {
    current_time=$(date +%s)
    override_until=$((current_time + OVERRIDE_DURATION))
    echo $override_until > "$STATE_FILE"
    echo "Override activated until $(date -d @$override_until)"
}

# Function to deactivate override
deactivate_override() {
    rm -f "$STATE_FILE"
    echo "Override deactivated"
}

# Check command line argument
case "$1" in
    "status")
        if is_override_active; then
            echo "Auto-adjustment is currently OVERRIDDEN"
            override_until=$(cat "$STATE_FILE")
            echo "Override expires at: $(date -d @$override_until)"
        else
            echo "Auto-adjustment is ACTIVE"
        fi
        echo "Current profile: $(get_current_profile)"
        echo "Current temp: $(get_temp)°C"
        ;;
    "override")
        activate_override
        echo "Manual override activated. Auto-adjustment suspended."
        ;;
    "resume")
        deactivate_override
        echo "Auto-adjustment resumed."
        ;;
    "force")
        # Force run even if override is active
        current_temp=$(get_temp)
        current_profile=$(get_current_profile)
        
        if (( $(echo "$current_temp < $TEMP_THRESHOLD_LOW" | bc -l) )); then
            target_profile="Balanced"
        elif (( $(echo "$current_temp > $TEMP_THRESHOLD_HIGH" | bc -l) )); then
            target_profile="Performance"
        else
            target_profile="Balanced"
        fi
        
        if [ "$target_profile" != "$current_profile" ]; then
            set_profile $target_profile
            echo "Temp $current_temp°C, Forced profile change to $target_profile (was $current_profile)"
        else
            echo "Profile $current_profile appropriate for temp $current_temp°C"
        fi
        ;;
    *)
        # Normal operation - only run if not in override mode
        if is_override_active; then
            echo "Auto-adjustment is overridden. Use 'temp_power_profile.sh resume' to reactivate."
            exit 0
        fi
        
        current_temp=$(get_temp)
        current_profile=$(get_current_profile)
        
        if (( $(echo "$current_temp < $TEMP_THRESHOLD_LOW" | bc -l) )); then
            target_profile="Balanced"
        elif (( $(echo "$current_temp > $TEMP_THRESHOLD_HIGH" | bc -l) )); then
            target_profile="Performance"
        else
            target_profile="Balanced"
        fi
        
        if [ "$target_profile" != "$current_profile" ]; then
            set_profile $target_profile
            echo "Temp $current_temp°C, Changed profile to $target_profile (was $current_profile)"
        else
            echo "Profile $current_profile appropriate for temp $current_temp°C"
        fi
        ;;
esac