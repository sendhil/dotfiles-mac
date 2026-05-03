#!/usr/bin/env bash
# Toggle Ghostty between TokyoNight Storm (dark) and TokyoNight Day (light).
# Rewrites the `theme = ...` line in ~/.config/ghostty/config and sends
# Cmd+Shift+, to Ghostty to trigger a live config reload.

set -euo pipefail

CONFIG="${HOME}/.config/ghostty/config"
DARK="TokyoNight Storm"
LIGHT="TokyoNight Day"
DARK_CURSOR="#7aa2f7"
LIGHT_CURSOR="#2e7de9"

if [[ ! -f "$CONFIG" ]]; then
  echo "Ghostty config not found at $CONFIG" >&2
  exit 1
fi

current=$(awk -F'=' '/^[[:space:]]*theme[[:space:]]*=/ {sub(/^[[:space:]]+/,"",$2); sub(/[[:space:]]+$/,"",$2); print $2; exit}' "$CONFIG")

if [[ "$current" == "$LIGHT" ]]; then
  new_theme="$DARK"
  new_cursor="$DARK_CURSOR"
  mode="dark"
else
  new_theme="$LIGHT"
  new_cursor="$LIGHT_CURSOR"
  mode="light"
fi

# Update theme line in-place so a symlinked config (via stow/dotfiles) is preserved.
tmp=$(mktemp)
awk -v new="$new_theme" -v cur="$new_cursor" '
  /^[[:space:]]*theme[[:space:]]*=/ { print "theme = " new; next }
  /^[[:space:]]*cursor-color[[:space:]]*=/ { print "cursor-color = " cur; next }
  { print }
' "$CONFIG" > "$tmp"
cat "$tmp" > "$CONFIG"
rm -f "$tmp"

echo "Switched Ghostty theme to $new_theme ($mode mode)"

# Trigger config reload in the frontmost Ghostty window.
if pgrep -xq Ghostty; then
  osascript <<'EOF' >/dev/null 2>&1 || true
tell application "System Events"
  tell process "Ghostty"
    keystroke "," using {command down, shift down}
  end tell
end tell
EOF
fi
