#!/bin/bash
# Stop any existing lockscreen
pkill -f "qs -c lockscreen"
# Start the new lockscreen
qs -c lockscreen & disown
