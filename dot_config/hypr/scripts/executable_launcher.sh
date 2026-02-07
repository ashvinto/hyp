#!/bin/bash

LAUNCHER_PATH="$HOME/.config/quickshell/launcher" 

# Check if running
if pgrep -f "qp -c $LAUNCHER_PATH" > /dev/null; then
    pkill -f "qs -c $LAUNCHER_PATH"
else
    echo "Opening launcher..." 
    # export QML_IMPORT_PATH="$HOME/.config/quickshell"  
    # Run
    qs -c "$LAUNCHER_PATH" > /dev/null 2>&1 & disown
fi

