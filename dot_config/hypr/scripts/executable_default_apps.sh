#!/bin/bash
# Simple Default App Changer

# List of common categories
categories=("Browser" "Terminal" "File Manager" "Editor" "Image Viewer" "PDF Viewer" "Video Player")

# Function to get installed .desktop files
get_apps() {
    ls /usr/share/applications/*.desktop $HOME/.local/share/applications/*.desktop 2>/dev/null | xargs -n1 basename | sed 's/\.desktop$//' | sort -u
}

# Pick category using fzf
choice=$(printf "%s\n" "${categories[@]}" | fzf --prompt="Select Category: " --layout=reverse --border)

[ -z "$choice" ] && exit 0

# Pick app using fzf
app=$(get_apps | fzf --prompt="Select Default for $choice: ")

[ -z "$app" ] && exit 0

case "$choice" in
    "Browser")
        # Use xdg-mime for better compatibility
        xdg-mime default "${app}.desktop" x-scheme-handler/http
        xdg-mime default "${app}.desktop" x-scheme-handler/https
        xdg-mime default "${app}.desktop" text/html
        ;;
    "Terminal")
        xdg-mime default "${app}.desktop" x-scheme-handler/terminal
        ;;
    "File Manager")
        xdg-mime default "${app}.desktop" inode/directory
        ;;
    "Editor")
        xdg-mime default "${app}.desktop" text/plain
        ;;
    "Image Viewer")
        xdg-mime default "${app}.desktop" image/jpeg
        xdg-mime default "${app}.desktop" image/png
        xdg-mime default "${app}.desktop" image/gif
        xdg-mime default "${app}.desktop" image/webp
        ;;
    "PDF Viewer")
        xdg-mime default "${app}.desktop" application/pdf
        ;;
    "Video Player")
        xdg-mime default "${app}.desktop" video/mp4
        xdg-mime default "${app}.desktop" video/x-matroska
        xdg-mime default "${app}.desktop" video/webm
        ;;
esac

notify-send "Default Apps" "Default $choice set to $app"