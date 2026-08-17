#!/bin/bash

set -eu

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$TEST_DIR/.." && pwd)
. "$TEST_DIR/test_helper.sh"

config_file="$ROOT_DIR/sway/.config/sway/config"
config=$(cat "$config_file" 2>/dev/null || true)

assert_contains "$config" 'set $mod Mod1' 'Sway uses Alt to preserve AeroSpace muscle memory'
assert_contains "$config" 'include ~/.config/sway/local.d/*.conf' \
  'Sway does not load optional machine-local input fragments'
assert_contains "$config" '# Intentional stock-i3 deviations: Alt preserves prior muscle memory; Vim h/j/k/l replaces stock j/k/l/semicolon.' \
  'config does not document the intentional modifier and Vim-navigation deviations from stock i3'
assert_contains "$config" '# Compatibility behavior: number keys toggle N/N+10; Alt+Shift+f remains a fullscreen alias.' \
  'config does not document the workspace-toggle and fullscreen deviations from stock i3'
if rg --hidden --no-ignore -ni 'aerospace' "$ROOT_DIR/sway" >/dev/null 2>&1; then
  fail 'Ubuntu-linked Sway files contain a macOS window-manager reference'
fi

for binding in \
  'bindsym $mod+h focus left' \
  'bindsym $mod+j focus down' \
  'bindsym $mod+k focus up' \
  'bindsym $mod+l focus right' \
  'bindsym $mod+Shift+h move left' \
  'bindsym $mod+Shift+j move down' \
  'bindsym $mod+Shift+k move up' \
  'bindsym $mod+Shift+l move right'
do
  assert_contains "$config" "$binding" "missing mirrored directional binding: $binding"
done

for digit in 1 2 3 4 5 6 7 8 9 0; do
  assert_contains "$config" \
    "bindsym \$mod+$digit exec ~/.local/bin/sway-workspace-toggle $digit" \
    "workspace digit $digit does not invoke the safe toggle helper"
done

for workspace in 1 2 3 4 5 6 7 8 9 10; do
  digit=$workspace
  [ "$workspace" -lt 10 ] || digit=0
  assert_contains "$config" \
    "bindsym \$mod+Shift+$digit move container to workspace number $workspace" \
    "primary workspace $workspace lacks a move binding"
done

assert_contains "$config" 'bindsym $mod+Shift+grave mode "workspace2"' \
  'secondary workspace mode is not reachable'
assert_contains "$config" 'mode "workspace2" {' 'secondary workspace mode is absent'
for workspace in 11 12 13 14 15 16 17 18 19 20; do
  digit=$((workspace - 10))
  [ "$workspace" -lt 20 ] || digit=0
  assert_contains "$config" "bindsym $digit workspace number $workspace, mode \"default\"" \
    "secondary workspace $workspace lacks a selection binding"
  assert_contains "$config" \
    "bindsym Shift+$digit move container to workspace number $workspace, mode \"default\"" \
    "secondary workspace $workspace lacks a move binding"
done

assert_contains "$config" 'bindsym $mod+Tab workspace back_and_forth' \
  'workspace back-and-forth binding is absent'
assert_contains "$config" 'bindsym $mod+grave exec ~/.local/bin/sway-scratchpad' \
  'native Sway scratchpad helper binding is absent'
assert_contains "$config" \
  'for_window [app_id="^wezterm-scratchpad$"] move scratchpad, scratchpad show' \
  'a newly launched scratch terminal is not moved into and shown from Sway scratchpad storage'
assert_contains "$config" 'bindsym $mod+r mode "resize"' 'resize mode binding is absent'
assert_contains "$config" 'mode "resize" {' 'resize mode is absent'
assert_contains "$config" 'mode "alternate" {' 'alternate mode is absent'
assert_contains "$config" 'mode "outputs" {' 'output mode is absent'
assert_contains "$config" 'focus output left' 'output mode cannot focus an adjacent output'
assert_contains "$config" 'move container to output left' 'output mode cannot move a container between outputs'
assert_contains "$config" 'bindsym $mod+Shift+space floating toggle' 'floating toggle is absent'
assert_contains "$config" 'set $term wezterm' 'WezTerm is not the configured terminal'
assert_contains "$config" 'bindsym $mod+Return exec $term' 'baseline terminal binding is absent'
assert_contains "$config" 'set $menu walker' 'Walker launcher command is absent'
assert_contains "$config" 'bindsym $mod+space exec $menu' 'Alt-Space launcher binding is absent'
assert_not_contains "$config" 'bindsym $mod+d exec $menu' 'retired Alt-d launcher binding remains'
assert_not_contains "$config" 'fuzzel' 'Sway still references unavailable Fuzzel'
assert_not_contains "$config" 'wofi' 'Sway still references retired Wofi'
assert_contains "$config" 'bindsym $mod+f fullscreen toggle' 'discoverable fullscreen binding is absent'
assert_contains "$config" 'bindsym $mod+Shift+f fullscreen toggle' \
  'AeroSpace fullscreen compatibility alias is absent'
assert_contains "$config" 'gaps inner 6' \
  'Sway inner gaps are not set to 6px'
assert_contains "$config" 'gaps outer 6' \
  'Sway outer gaps are not set to 6px'
assert_contains "$config" 'smart_gaps on' \
  'Sway smart gaps are not enabled'

assert_contains "$config" \
  'exec_always dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway' \
  'Sway does not publish its Wayland environment to user services'
assert_contains "$config" 'XF86AudioRaiseVolume' 'media volume bindings are absent'
assert_contains "$config" 'XF86MonBrightnessUp' 'brightness bindings are absent'
assert_contains "$config" 'grim -g "$(slurp)"' 'interactive screenshot binding is absent'
assert_contains "$config" 'exec swaylock' 'lock binding is absent'
assert_contains "$config" "swaynag -t warning -m 'Exit Sway?'" 'session exit confirmation is absent'

for rule in \
  'assign [app_id="^google-chrome$"] workspace number 1' \
  'assign [class="^Google-chrome$"] workspace number 1' \
  'assign [app_id="^code$"] workspace number 2' \
  'assign [class="^Code$"] workspace number 2' \
  'assign [app_id="^obsidian$"] workspace number 9' \
  'assign [class="^obsidian$"] workspace number 9' \
  'assign [app_id="^Slack$"] workspace number 10' \
  'assign [class="^Slack$"] workspace number 10'
do
  assert_contains "$config" "$rule" "known Linux application route is absent: $rule"
done

assert_not_contains "$config" 'assign [app_id="^org.wezfurlong.wezterm$"]' \
  'normal WezTerm windows are forced away from the current workspace'

assert_not_contains "$config" 'Outlook' 'Sway guesses an unobserved Outlook identifier'
assert_not_contains "$config" 'outlook' 'Sway guesses an unobserved Outlook identifier'
assert_not_contains "$config" 'DELL S2722QC' 'Sway contains a hardcoded desktop monitor'
assert_not_contains "$config" 'Built-in' 'Sway contains a hardcoded laptop output'
if rg -n '^[[:space:]]*(output|workspace)[[:space:]].*(eDP|DP-|HDMI-|DVI-|DisplayPort)' \
  "$config_file" >/dev/null 2>&1; then
  fail 'Sway contains a fixed output identifier or workspace-to-output assignment'
fi

route_line_count=$(printf '%s\n' "$config" | awk '/^assign \[(app_id|class)=/{count++} END {print count+0}')
[ "$route_line_count" -eq 8 ] || fail 'application criteria are not isolated on one rule per line'

case $(git -C "$ROOT_DIR" check-ignore -v sway/.config/sway/local.d/laptop.conf 2>/dev/null || true) in
  '') fail 'machine-local Sway fragments are not ignored' ;;
esac

pass 'Sway config mirrors AeroSpace and documents intentional stock-i3 deviations'
