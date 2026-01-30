#!/bin/bash
if pgrep -f "qs -c dashboard" > /dev/null; then
    pkill -f "qs -c dashboard"
else
    qs -c dashboard & disown
fi
