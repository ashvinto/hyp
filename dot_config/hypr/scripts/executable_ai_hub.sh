#!/bin/bash

# Target URL (ChatGPT by default)
URL="https://chatgpt.com"

# If an argument is passed, use it as the URL
case $1 in
    claude) URL="https://claude.ai" ;;
    gemini) URL="https://gemini.google.com" ;;
    perplexity) URL="https://perplexity.ai" ;;
esac

# Launch Brave in App Mode
# --app makes it a standalone window without tabs/address bar
# --window-size sets the initial size
# --class sets a custom name so we can apply Hyprland rules
brave --app="$URL" --class="ai-hub" --window-size=1100,750
