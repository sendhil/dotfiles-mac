#!/bin/bash
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
case "$1" in
  clock)
    sketchybar --set mocha.clock label="$(date '+%a %d %b  %-I:%M %p')"
    ;;
  battery)
    batt="$(pmset -g batt)"
    percent="$(printf '%s' "$batt" | sed -nE 's/.*[[:space:]]([0-9]+)%;.*/\1/p')"
    if [ -z "$percent" ]; then
      sketchybar --set mocha.battery drawing=off
      exit 0
    fi
    color=0xffa6e3a1
    icon=
    if [ "$percent" -lt 80 ]; then icon=; fi
    if [ "$percent" -lt 50 ]; then icon=; fi
    if [ "$percent" -lt 25 ]; then icon=; color=0xfff9e2af; fi
    if [ "$percent" -le 15 ]; then icon=; color=0xfff38ba8; fi
    if [[ "$batt" == *"AC Power"* ]]; then icon=; fi
    sketchybar --set mocha.battery drawing=on icon="$icon" icon.color="$color" label="$percent%"
    ;;
  volume)
    if [ "$SENDER" = mouse.exited.global ]; then
      sketchybar --set mocha.volume popup.drawing=off
      exit 0
    fi
    if [ "$SENDER" = mouse.scrolled ]; then
      "$(dirname "$0")/action.sh" scroll
      exit 0
    fi
    volume="$(osascript -e 'output volume of (get volume settings)' 2>/dev/null)"
    muted="$(osascript -e 'output muted of (get volume settings)' 2>/dev/null)"
    [[ "$volume" =~ ^[0-9]+$ ]] || exit 0
    icon=󰕾
    if [ "$muted" = true ] || [ "$volume" = 0 ]; then icon=󰖁; fi
    sketchybar --set mocha.volume icon="$icon" label="$volume%" \
      --set mocha.volume.slider slider.percentage="$volume"
    ;;
  network)
    if scutil --nwi | /usr/bin/grep -q 'Network interfaces:'; then
      sketchybar --set mocha.network icon=󰖩 icon.color=0xff94e2d5
    else
      sketchybar --set mocha.network icon=󰖪 icon.color=0xfff38ba8
    fi
    ;;
  front)
    if [ "$SENDER" = front_app_switched ] && [ -n "$INFO" ]; then
      sketchybar --set mocha.front label="$INFO"
    fi
    ;;
esac
