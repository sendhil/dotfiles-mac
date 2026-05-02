#!/usr/bin/env bash
# Quake-style toggle for a floating cmux scratchpad window.
# Bound to alt-backtick in aerospace.toml; parks the window on the
# "Floating" AeroSpace workspace to toggle visibility without the Genie
# minimize animation.
set -euo pipefail

SENTINEL='»scratch«'
PARK='Floating'
CMUX="${CMUX_BUNDLED_CLI_PATH:-/Applications/cmux.app/Contents/Resources/bin/cmux}"

# Center the scratch window at 60%×75% of the main screen's visible frame.
center_scratch_window() {
  osascript <<'APPLESCRIPT' >/dev/null 2>&1 || true
    use framework "AppKit"
    use scripting additions
    set vf to current application's NSScreen's mainScreen()'s visibleFrame()
    set sx to (item 1 of item 1 of vf) as integer
    set sy to (item 2 of item 1 of vf) as integer
    set sw to (item 1 of item 2 of vf) as integer
    set sh to (item 2 of item 2 of vf) as integer
    set winW to (sw * 0.6) as integer
    set winH to (sh * 0.75) as integer
    set winX to (sx + ((sw - winW) / 2)) as integer
    set winY to (sy + ((sh - winH) / 2)) as integer
    tell application "System Events"
      set targetWin to first window of application process "cmux" whose title contains "»scratch«"
      set position of targetWin to {winX, winY}
      set size of targetWin to {winW, winH}
    end tell
APPLESCRIPT
}

read -r WINDOW_ID WINDOW_WS <<<"$(aerospace list-windows --all \
  --format '%{window-id} %{app-bundle-id} %{workspace} %{window-title}' --json \
  | jq -r --arg s "$SENTINEL" \
      'first(.[] | select(."app-bundle-id" == "com.cmuxterm.app"
                          and ((."window-title" // "") | contains($s)))
                 | "\(."window-id") \(.workspace)") // ""')"

if [ -z "$WINDOW_ID" ]; then
  new_window_line=$("$CMUX" new-window)
  new_window_uuid=${new_window_line#OK }
  ws_uuid=$("$CMUX" list-workspaces --window "$new_window_uuid" --id-format uuids \
    | awk '{print $2}' | head -n1)
  "$CMUX" rename-workspace --workspace "$ws_uuid" "$SENTINEL" >/dev/null
  sleep 0.15
  center_scratch_window
  exit 0
fi

CURRENT_WS=$(aerospace list-workspaces --focused)

if [ "$WINDOW_WS" = "$CURRENT_WS" ]; then
  aerospace move-node-to-workspace --window-id "$WINDOW_ID" "$PARK"
else
  aerospace layout floating --window-id "$WINDOW_ID" 2>/dev/null || true
  aerospace move-node-to-workspace --window-id "$WINDOW_ID" "$CURRENT_WS"
  aerospace focus --window-id "$WINDOW_ID"
fi
