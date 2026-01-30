#!/bin/zsh

killall -9 waybar

# Ensure dunst is running if needed, or just leave it be (it's exec-once in hyprland)
# dunst & 

waybar &
