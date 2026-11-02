#!/usr/bin/env bash
# Persist a Ghostty theme without editing the stowed base configuration.
set -euo pipefail
umask 077

STATE_DIR="$HOME/.local/state/dotfiles-mac/ghostty"
STATE_FILE="$STATE_DIR/theme.ghostty"
TEMP_FILE=""
trap 'if [[ -n "$TEMP_FILE" ]]; then rm -f -- "$TEMP_FILE"; fi' EXIT

find_ghostty() {
  if [[ -n "${GHOSTTY_BIN:-}" ]]; then
    printf '%s\n' "$GHOSTTY_BIN"
  elif command -v ghostty >/dev/null 2>&1; then
    command -v ghostty
  elif [[ -x /Applications/Ghostty.app/Contents/MacOS/ghostty ]]; then
    printf '%s\n' /Applications/Ghostty.app/Contents/MacOS/ghostty
  else
    echo 'Ghostty binary not found.' >&2
    return 1
  fi
}

favorites() {
  cat <<'THEMES'
TokyoNight Storm
TokyoNight Night
TokyoNight Day
Catppuccin Mocha
Catppuccin Macchiato
Catppuccin Frappe
Catppuccin Latte
iTerm2 Solarized Dark
iTerm2 Solarized Light
Atom One Dark
Atom One Light
Nord
Rose Pine
Rose Pine Dawn
Kanagawa Wave
Everforest Dark Med
Everforest Light Med
Nightfox
Ayu
Ayu Light
Ayu Mirage
THEMES
}

current_theme() {
  local file="$HOME/.config/ghostty/config" theme=""
  if [[ -f "$STATE_FILE" ]]; then file="$STATE_FILE"; fi
  if [[ -f "$file" ]]; then
    theme=$(awk -F'=' '/^[[:space:]]*theme[[:space:]]*=/ {sub(/^[[:space:]]+/, "", $2); sub(/[[:space:]]+$/, "", $2); print $2; exit}' "$file")
  fi
  printf '%s\n' "${theme:-TokyoNight Storm}"
}

available_themes() {
  local ghostty
  ghostty=$(find_ghostty)
  "$ghostty" +list-themes --plain | sed 's/ ([^()]*)$//'
}

theme_cursor() {
  local ghostty="$1" theme="$2" path
  path=$("$ghostty" +list-themes --plain --path | awk -v theme="$theme" '
    !found && index($0, theme " (") == 1 {
      path = substr($0, length(theme) + 2)
      sub(/^\([^)]*\) /, "", path)
      found = 1
    }
    END {print path}
  ')
  if [[ ! -f "$path" ]]; then
    printf 'Cannot read the theme file for %s.\n' "$theme" >&2
    return 1
  fi
  awk -F'=' '
    /^[[:space:]]*cursor-color[[:space:]]*=/ {
      color = $2
      sub(/^[[:space:]]+/, "", color)
      sub(/[[:space:]]+$/, "", color)
    }
    END {print (color != "" ? color : "cell-foreground") }
  ' "$path"
}

reload_ghostty() {
  if ! pgrep -xq Ghostty; then return 0; fi
  local result
  if result=$(osascript -e 'tell application "Ghostty"' -e 'if (count of terminals) is 0 then return false' -e 'return perform action "reload_config" on first terminal' -e 'end tell' 2>&1); then
    if [[ "$result" == 'true' ]]; then return 0; fi
  fi
  printf 'Theme saved; press Cmd+Shift+, to reload Ghostty manually. %s\n' "$result" >&2
  return 0
}

save_theme() {
  local theme="$1" ghostty cursor available
  if [[ "$theme" == *$'\n'* || "$theme" == *$'\r'* ]]; then
    echo 'Theme names must be a single line.' >&2
    return 1
  fi
  if ! favorites | grep -Fxq -- "$theme"; then
    printf 'Not a favorite theme: %s\n' "$theme" >&2
    return 1
  fi
  ghostty=$(find_ghostty)
  available=$(available_themes)
  if ! printf '%s\n' "$available" | grep -Fxq -- "$theme"; then
    printf 'Theme is not installed: %s\n' "$theme" >&2
    return 1
  fi
  case "$theme" in
    'TokyoNight Storm') cursor='#7aa2f7' ;;
    'TokyoNight Day') cursor='#2e7de9' ;;
    *) cursor=$(theme_cursor "$ghostty" "$theme") ;;
  esac
  mkdir -p "$STATE_DIR"
  TEMP_FILE=$(mktemp "$STATE_DIR/.theme.XXXXXX")
  printf 'theme = %s\ncursor-color = %s\n' "$theme" "$cursor" > "$TEMP_FILE"
  "$ghostty" +validate-config --config-file="$TEMP_FILE"
  mv -f -- "$TEMP_FILE" "$STATE_FILE"
  TEMP_FILE=""
  printf 'Ghostty theme: %s\n' "$theme"
  reload_ghostty
}

pick_theme() {
  local theme available choices
  if ! command -v fzf >/dev/null 2>&1; then
    echo 'fzf is required for the favorites picker.' >&2
    return 1
  fi
  available=$(available_themes)
  choices=$(while IFS= read -r theme; do
    if printf '%s\n' "$available" | grep -Fxq -- "$theme"; then printf '%s\n' "$theme"; fi
  done < <(favorites))
  if [[ -z "$choices" ]]; then
    echo 'No favorite themes are installed in this Ghostty.' >&2
    return 1
  fi
  if theme=$(printf '%s\n' "$choices" | fzf --height=70% --layout=reverse --border --no-multi --prompt='Ghostty theme > ' --header='Enter: apply to all Ghostty windows | Esc: cancel'); then
    if [[ -n "$theme" ]]; then save_theme "$theme"; fi
  else
    local status=$?
    case "$status" in
      1|130) return 0 ;;
      *) echo 'Theme picker failed.' >&2; return "$status" ;;
    esac
  fi
}

usage() {
  echo 'Usage: theme.sh [pick|toggle|reset|current|set THEME]'
  echo 'Default: searchable favorites picker. Themes persist locally across Ghostty windows.'
}

case "${1:-pick}" in
  --help|-h|help) usage ;;
  pick) [[ $# -le 1 ]] || exit 2; pick_theme ;;
  reset) [[ $# -eq 1 ]] || exit 2; rm -f -- "$STATE_FILE"; printf 'Ghostty theme reset: %s\n' "$(current_theme)"; reload_ghostty ;;
  current) [[ $# -eq 1 ]] || exit 2; current_theme ;;
  set) [[ $# -eq 2 ]] || exit 2; save_theme "$2" ;;
  toggle) [[ $# -eq 1 ]] || exit 2; if [[ "$(current_theme)" == 'TokyoNight Day' ]]; then save_theme 'TokyoNight Storm'; else save_theme 'TokyoNight Day'; fi ;;
  *) usage >&2; exit 2 ;;
esac
