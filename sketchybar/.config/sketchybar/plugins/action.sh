#!/bin/bash
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
case "$1" in
  volume)
    if [ "$BUTTON" = right ]; then
      open 'x-apple.systempreferences:com.apple.Sound-Settings.extension'
    else
      sketchybar --set mocha.volume popup.drawing=toggle
    fi
    ;;
  slider)
    value="${PERCENTAGE%%.*}"
    if [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -le 100 ]; then
      osascript -e "set volume output volume $value"
      "$(dirname "$0")/status.sh" volume
    fi
    ;;
  scroll)
    old="$(osascript -e 'output volume of (get volume settings)' 2>/dev/null)"
    [[ "$old" =~ ^[0-9]+$ ]] || exit 0
    case "$SCROLL_DELTA" in
      -*) value=$((old - 5)) ;;
      *) value=$((old + 5)) ;;
    esac
    [ "$value" -gt 100 ] && value=100
    [ "$value" -lt 0 ] && value=0
    osascript -e "set volume output volume $value"
    SENDER=volume_change "$(dirname "$0")/status.sh" volume
    ;;
esac
