#!/bin/bash
TMP_FILE="/tmp/qs_screenshot_edit.png"

open_satty() {
    wl-copy < "$TMP_FILE"
    satty --filename "$TMP_FILE" --early-exit --copy-command "wl-copy"
}

case "$1" in
    "area") grim -g "$(slurp)" "$TMP_FILE" && open_satty ;;
    "full") grim "$TMP_FILE" && open_satty ;;
    "window") grim -g "$(slurp)" "$TMP_FILE" && open_satty ;;
    "freeze")
        grim /tmp/qs_freeze.png
        QS_SCREENSHOT_MODE=overlay qs -c screenshot & disown
        ;;
    *)
        if pgrep -f "qs -c screenshot" > /dev/null; then pkill -f "qs -c screenshot"
        else qs -c screenshot & disown; fi
        ;;
esac