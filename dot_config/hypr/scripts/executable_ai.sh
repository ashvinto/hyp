if pgrep -f "zero-ai" > /dev/null; then
    pkill -f "zero-ai"
else
    zero-ai & disown
fi
