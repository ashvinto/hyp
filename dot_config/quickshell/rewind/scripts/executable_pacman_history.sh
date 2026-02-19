#!/bin/bash
# scripts/pacman_history.sh
# Faster, valid JSON parsing using AWK

LOG_FILE="/var/log/pacman.log"

# Read last 300 lines, filter for actions, and process
tail -n 300 "$LOG_FILE" | grep -E "installed|upgraded|removed" | awk '
BEGIN {
    # Store lines in an array to reverse them later (newest first)
    count = 0
}
{
    # Line format: [2024-02-09T17:00:00+0530] [ALPM] action package (details)
    
    # Extract timestamp (remove brackets)
    raw_time = substr($1, 2, length($1)-2)
    # Simplify time: 2024-02-09T17:00:00+0530 -> 2024-02-09 17:00
    gsub("T", " ", raw_time)
    split(raw_time, t_parts, "+")
    time = t_parts[1]
    
    # Action is $3, Package is $4
    action = $3
    pkg = $4
    
    # Details is everything after $4
    details = ""
    for (i=5; i<=NF; i++) {
        details = details $i " "
    }
    gsub("\"", "\\\"", details) # Escape quotes
    
    # Store in array
    lines[count++] = sprintf("  {\n    \"time\": \"%s\",\n    \"action\": \"%s\",\n    \"package\": \"%s\",\n    \"details\": \"%s\"\n  }", time, action, pkg, details)
}
END {
    print "["
    # Print in reverse order (newest first)
    for (i = count - 1; i >= 0; i--) {
        printf "%s", lines[i]
        if (i > 0) print ","
        else print ""
    }
    print "]"
}
'
