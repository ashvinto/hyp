#!/bin/bash

# Script to control media playback with memory of last selected player
action=${1:-play-pause}

# File to store the last selected player
STATE_FILE="/tmp/.playerctl_last_selected"

# Get all available players
all_players=$(playerctl -l 2>/dev/null)

if [ -z "$all_players" ]; then
    exit 0
fi

# Debug: Log all players and their status
echo "$(date): Available players: $all_players" >> /tmp/player_debug.log

selected_player=""

# First, check if any player is currently playing
for player in $all_players; do
    status=$(playerctl --player="$player" status 2>/dev/null)
    echo "$(date): Player '$player' status: $status" >> /tmp/player_debug.log
    
    if [[ "$status" == "Playing" ]]; then
        selected_player="$player"
        # Save this as the last selected player
        echo "$selected_player" > "$STATE_FILE"
        break
    fi
done

# If no player is playing, check for paused players
if [ -z "$selected_player" ]; then
    # First, check if the last selected player is still paused
    if [ -f "$STATE_FILE" ]; then
        last_selected=$(cat "$STATE_FILE")
        # Verify the last selected player still exists and is paused
        if echo "$all_players" | grep -q "$last_selected"; then
            last_status=$(playerctl --player="$last_selected" status 2>/dev/null)
            if [[ "$last_status" == "Paused" ]]; then
                selected_player="$last_selected"
            fi
        fi
    fi

    # If we still don't have a selected player, use the first paused one
    if [ -z "$selected_player" ]; then
        for player in $all_players; do
            status=$(playerctl --player="$player" status 2>/dev/null)
            if [[ "$status" == "Paused" ]]; then
                selected_player="$player"
                break
            fi
        done
    fi
fi

# If we found a player to control
if [ -n "$selected_player" ]; then
    # Update the last selected player
    echo "$selected_player" > "$STATE_FILE"
    echo "$(date): Selected player: $selected_player" >> /tmp/player_debug.log
    echo "$(date): Controlling player: $selected_player with action: $action" >> /tmp/player_debug.log
    playerctl --player="$selected_player" "$action"
else
    # Fallback to default behavior
    echo "$(date): No specific player found, using default" >> /tmp/player_debug.log
    playerctl "$action"
fi