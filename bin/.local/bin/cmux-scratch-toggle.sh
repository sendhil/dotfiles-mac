#!/usr/bin/env bash
# Quake-style toggle for a floating cmux scratchpad window.
# Bound to alt-grave in aerospace.toml; parks the window on the "Floating"
# AeroSpace workspace instead of closing it so shell state persists.
set -euo pipefail

SENTINEL='»scratch«'
PARK='Floating'
CMUX="${CMUX_BUNDLED_CLI_PATH:-/Applications/cmux.app/Contents/Resources/bin/cmux}"

WINDOW_ID=$(aerospace list-windows --all --format '%{window-id} %{app-bundle-id} %{workspace} %{window-title}' --json \
  | jq -r --arg s "$SENTINEL" \
      '.[] | select(."app-bundle-id" == "com.cmuxterm.app"
                    and ((."window-title" // "") | contains($s)))
           | ."window-id"' \
  | head -n1)

if [ -z "$WINDOW_ID" ]; then
  new_window_line=$("$CMUX" new-window)
  new_window_uuid=${new_window_line#OK }
  ws_uuid=$("$CMUX" list-workspaces --window "$new_window_uuid" --id-format uuids \
    | awk '{print $2}' | head -n1)
  "$CMUX" rename-workspace --workspace "$ws_uuid" "$SENTINEL" >/dev/null
  exit 0
fi

CURRENT_WS=$(aerospace list-workspaces --focused)
WINDOW_WS=$(aerospace list-windows --all --format '%{window-id} %{app-bundle-id} %{workspace} %{window-title}' --json \
  | jq -r --argjson id "$WINDOW_ID" \
      '.[] | select(."window-id" == $id) | .workspace')

if [ "$WINDOW_WS" = "$CURRENT_WS" ]; then
  aerospace move-node-to-workspace --window-id "$WINDOW_ID" "$PARK"
else
  aerospace move-node-to-workspace --window-id "$WINDOW_ID" "$CURRENT_WS"
  aerospace focus --window-id "$WINDOW_ID"
fi
