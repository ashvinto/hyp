#!/bin/bash
# scripts/pacman_history.sh
# Reads the last 50 entries from pacman.log and formats them as JSON

LOG_FILE="/var/log/pacman.log"

echo "["
first=true

# Tail the log, reverse it (newest first), filter for relevant actions
tail -n 200 "$LOG_FILE" | grep -E "installed|upgraded|removed" | tac | while read -r line; do
    # Format: [2023-10-25T12:00:00-0400] [ALPM] upgraded foobar (1.0 -> 1.1) 
    
    # Extract timestamp (between brackets)
    timestamp=$(echo "$line" | grep -oP '^[\[\]\][^\\\]]+\K')
    
    # Extract action and package info
    # Remove timestamp and [ALPM] prefix
    content=$(echo "$line" | sed -E 's/^[[^]]+] [[A-Z]+] //')
    
    action=$(echo "$content" | awk '{print $1}')
    pkg=$(echo "$content" | awk '{print $2}')
    
    # Get details (versions)
    details=$(echo "$content" | cut -d' ' -f3-)
    
    if [ "$first" = true ]; then
        first=false
    else
        echo ","
    fi
    
    # JSON output
    echo "  {"
    echo "    \"time\": \"$timestamp\","
    echo "    \"action\": \"$action\","
    echo "    \"package\": \"$pkg\","
    echo "    \"details\": \"$details\""
    echo "  }"
done
echo "]"
