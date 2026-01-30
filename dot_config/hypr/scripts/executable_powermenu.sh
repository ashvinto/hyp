#!/bin/bash
if pgrep -f "qs -c powermenu" > /dev/null; then
    pkill -f "qs -c powermenu"
else
    qs -c powermenu & disown
fi
