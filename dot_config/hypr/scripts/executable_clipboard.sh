#!/bin/bash
if pgrep -f "qs -c clipboard" > /dev/null; then
    pkill -f "qs -c clipboard"
else
    qs -c clipboard & disown
fi
