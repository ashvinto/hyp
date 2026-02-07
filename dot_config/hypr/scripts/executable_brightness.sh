#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
iDIR="$HOME/.config/swaync/icons"
notification_timeout=1000
step=10

get_backlight() {
	brightnessctl -m | cut -d, -f4 | sed 's/%//'
}

get_icon() {
	current=$(get_backlight)
	if   [ "$current" -le "20" ]; then icon="$iDIR/brightness-20.png"
	elif [ "$current" -le "40" ]; then icon="$iDIR/brightness-40.png"
	elif [ "$current" -le "60" ]; then icon="$iDIR/brightness-60.png"
	elif [ "$current" -le "80" ]; then icon="$iDIR/brightness-80.png"
	else icon="$iDIR/brightness-100.png"; fi
}

notify_user() {
	notify-send -e -h string:x-canonical-private-synchronous:brightness_notif -h int:value:$current -u low -i $icon "Screen" "Brightness:$current%"
}

change_backlight() {
	local current_brightness
	current_brightness=$(get_backlight)
	local state_file="$HOME/.config/hypr/configs/shader_state.conf"
    local manager="$HOME/.config/hypr/scripts/shader_man.sh"

	local sw_bright=100
	if [ -f "$state_file" ]; then
		sw_bright=$(grep "DIM_LEVEL=" "$state_file" | cut -d= -f2)
		[ -z "$sw_bright" ] && sw_bright=100
	fi

	if [[ "$1" == "+${step}%" ]]; then
		if (( sw_bright < 100 )); then
			sw_bright=$((sw_bright + 10))
            if (( sw_bright > 100 )); then sw_bright=100; fi
            "$manager" --dim "$sw_bright"
            if (( sw_bright == 100 )); then notify-send -e -u low "Screen" "Software Dimming Disabled"
            else notify-send -e -u low "Screen" "Software Brightness: ${sw_bright}%"; fi
			return
		fi
		new_brightness=$((current_brightness + step))
	elif [[ "$1" == "${step}%-" ]]; then
		if (( current_brightness <= 1 )); then
			if (( sw_bright > 10 )); then
				sw_bright=$((sw_bright - 10))
                "$manager" --dim "$sw_bright"
				notify-send -e -u low "Screen" "Software Brightness: ${sw_bright}%"
				return
			fi
		fi
		new_brightness=$((current_brightness - step))
	fi

	if (( new_brightness < 1 )); then new_brightness=1
	elif (( new_brightness > 100 )); then new_brightness=100; fi

	brightnessctl set "${new_brightness}%"
	get_icon
	current=$new_brightness
	notify_user
}

case "$1" in
	"--get") get_backlight ;;
	"--inc") change_backlight "+${step}%" ;;
	"--dec") change_backlight "${step}%-" ;;
	*) get_backlight ;;
esac
