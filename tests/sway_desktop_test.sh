#!/bin/bash

set -eu

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$TEST_DIR/.." && pwd)
. "$TEST_DIR/test_helper.sh"

sway_config_file="$ROOT_DIR/sway/.config/sway/config"
waybar_config_file="$ROOT_DIR/waybar/.config/waybar/config.jsonc"
desktop_packages='waybar wofi mako swaylock xdg-portal'

for package in $desktop_packages; do
  [ -d "$ROOT_DIR/$package" ] || fail "desktop package is absent: $package"
done

for config_file in \
  "$waybar_config_file" \
  "$ROOT_DIR/waybar/.config/waybar/style.css" \
  "$ROOT_DIR/wofi/.config/wofi/config" \
  "$ROOT_DIR/wofi/.config/wofi/style.css" \
  "$ROOT_DIR/mako/.config/mako/config" \
  "$ROOT_DIR/swaylock/.config/swaylock/config" \
  "$ROOT_DIR/xdg-portal/.config/xdg-desktop-portal/portals.conf"
do
  [ -f "$config_file" ] || fail "desktop config is absent: ${config_file#"$ROOT_DIR/"}"
done

sway_config=$(cat "$sway_config_file")
for command in \
  'waybar' \
  'mako' \
  'nm-applet --indicator' \
  'blueman-applet' \
  'swayidle -w' \
  '/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1'
do
  count=$(printf '%s\n' "$sway_config" | awk -v command="$command" \
    'index($0, command) && $0 ~ /^[[:space:]]*exec[[:space:]]/ { count++ } END { print count+0 }')
  [ "$count" -eq 1 ] || fail "Sway must start exactly one instance of: $command"
done

idle_sequence="exec swayidle -w timeout 300 'swaylock -f' timeout 600 'swaymsg \"output * power off\"' resume 'swaymsg \"output * power on\"' before-sleep 'swaylock -f'"
assert_contains "$sway_config" "$idle_sequence" \
  'idle handling does not lock, power down, resume, and sleep-lock in the required order'

if printf '%s\n' "$sway_config" | rg '^[[:space:]]*exec_always[[:space:]].*(waybar|mako|nm-applet|blueman-applet|swayidle|polkit-gnome)' >/dev/null; then
  fail 'desktop companions use exec_always and would duplicate after Sway reloads'
fi

python3 - "$waybar_config_file" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
lines = [line for line in path.read_text().splitlines() if not line.lstrip().startswith("//")]
config = json.loads("\n".join(lines))

expected = {
    "sway/workspaces",
    "wireplumber",
    "network",
    "bluetooth",
    "battery",
    "backlight",
    "clock",
}
configured = {
    module
    for key in ("modules-left", "modules-center", "modules-right")
    for module in config.get(key, [])
}
missing = expected - configured
if missing:
    raise SystemExit(f"not ok - Waybar is missing modules: {', '.join(sorted(missing))}")

guarded_clicks = {
    "wireplumber": "pavucontrol",
    "network": "nm-connection-editor",
    "bluetooth": "blueman-manager",
}
for module, command in guarded_clicks.items():
    handler = config.get(module, {}).get("on-click", "")
    expected_guard = f"command -v {command} >/dev/null 2>&1 && exec {command}"
    if handler != expected_guard:
        raise SystemExit(f"not ok - {module} click handler is not safely guarded")
PY

portal_config=$(cat "$ROOT_DIR/xdg-portal/.config/xdg-desktop-portal/portals.conf")
assert_contains "$portal_config" 'default=wlr;gtk' \
  'portal preference does not select wlr with GTK fallback'
assert_contains "$portal_config" 'org.freedesktop.impl.portal.FileChooser=gtk' \
  'file chooser portal is not explicitly delegated to GTK'

mako_config=$(cat "$ROOT_DIR/mako/.config/mako/config")
assert_contains "$mako_config" 'default-timeout=' 'Mako has no default notification timeout'
assert_contains "$mako_config" '[urgency=critical]' 'Mako has no critical-notification policy'
assert_contains "$mako_config" 'default-timeout=0' 'critical Mako notifications do not persist'

swaylock_config=$(cat "$ROOT_DIR/swaylock/.config/swaylock/config")
assert_contains "$swaylock_config" 'indicator' 'Swaylock does not show its authentication indicator'

for themed_config in \
  "$ROOT_DIR/waybar/.config/waybar/style.css" \
  "$ROOT_DIR/wofi/.config/wofi/style.css" \
  "$ROOT_DIR/mako/.config/mako/config" \
  "$ROOT_DIR/swaylock/.config/swaylock/config"
do
  rg -q '1a1b26' "$themed_config" || fail "desktop config does not use the Tokyo Night background: ${themed_config#"$ROOT_DIR/"}"
done

if rg -n '(/Users/|/home/|eDP(-[0-9]+)?|DP-[0-9]+|HDMI-[A-Z]-[0-9]+|DVI-[A-Z]-[0-9]+)' \
  "$ROOT_DIR/waybar/.config" \
  "$ROOT_DIR/wofi/.config" \
  "$ROOT_DIR/mako/.config" \
  "$ROOT_DIR/swaylock/.config" \
  "$ROOT_DIR/xdg-portal/.config" \
  >/dev/null 2>&1; then
  fail 'desktop companion configs contain a host path or fixed output name'
fi

if rg -ni 'fuzzel' \
  "$ROOT_DIR/scripts/package-set.sh" \
  "$ROOT_DIR/sway/.config" \
  "$ROOT_DIR/wofi/.config" \
  >/dev/null 2>&1; then
  fail 'selected Ubuntu desktop configuration still references Fuzzel'
fi

pass 'Sway desktop companions are cohesive, portable, and reload-safe'
