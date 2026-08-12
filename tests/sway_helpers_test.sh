#!/bin/bash

set -eu

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$TEST_DIR/.." && pwd)
. "$TEST_DIR/test_helper.sh"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM

fake_bin="$tmp_dir/fake bin"
mkdir -p "$fake_bin"

cat >"$fake_bin/swaymsg" <<'FAKE_SWAYMSG'
#!/bin/sh
{
  printf 'swaymsg'
  for arg do
    printf ' <%s>' "$arg"
  done
  printf '\n'
} >>"$SWAYMSG_LOG"

case "$*" in
  '-t get_workspaces -r')
    [ "${SWAYMSG_WORKSPACES_STATUS:-0}" -eq 0 ] || exit "$SWAYMSG_WORKSPACES_STATUS"
    if [ "${SWAYMSG_WORKSPACES_JSON+set}" = set ]; then
      printf '%s\n' "$SWAYMSG_WORKSPACES_JSON"
    else
      printf '%s\n' '[]'
    fi
    ;;
  '-t get_tree -r')
    [ "${SWAYMSG_TREE_STATUS:-0}" -eq 0 ] || exit "$SWAYMSG_TREE_STATUS"
    if [ "${SWAYMSG_TREE_JSON+set}" = set ]; then
      printf '%s\n' "$SWAYMSG_TREE_JSON"
    else
      printf '%s\n' '{}'
    fi
    ;;
  *)
    [ "${SWAYMSG_COMMAND_STATUS:-0}" -eq 0 ] || exit "$SWAYMSG_COMMAND_STATUS"
    if [ "${SWAYMSG_COMMAND_JSON+set}" = set ]; then
      printf '%s\n' "$SWAYMSG_COMMAND_JSON"
    else
      printf '%s\n' '[{"success":true}]'
    fi
    ;;
esac
FAKE_SWAYMSG

cat >"$fake_bin/kitty" <<'FAKE_KITTY'
#!/bin/sh
{
  printf 'kitty'
  for arg do
    printf ' <%s>' "$arg"
  done
  printf '\n'
} >>"$KITTY_LOG"
exit "${KITTY_STATUS:-0}"
FAKE_KITTY
chmod +x "$fake_bin/swaymsg" "$fake_bin/kitty"

workspace_helper="$ROOT_DIR/sway/.local/bin/sway-workspace-toggle"
scratch_helper="$ROOT_DIR/sway/.local/bin/sway-scratchpad"
log="$tmp_dir/swaymsg log"
kitty_log="$tmp_dir/kitty log"
: >"$log"
: >"$kitty_log"

run_workspace() {
  focused=$1
  digit=$2
  : >"$log"
  PATH="$fake_bin:$PATH" SWAYMSG_LOG="$log" \
    SWAYMSG_WORKSPACES_JSON="[{\"num\":$focused,\"focused\":true}]" \
    "$workspace_helper" "$digit"
}

run_workspace 1 1
assert_contains "$(cat "$log")" 'swaymsg <--> <workspace number 11>' \
  'Alt+1 from workspace 1 selects paired workspace 11'

run_workspace 11 1
assert_contains "$(cat "$log")" 'swaymsg <--> <workspace number 1>' \
  'Alt+1 from workspace 11 returns to workspace 1'

run_workspace 3 1
assert_contains "$(cat "$log")" 'swaymsg <--> <workspace number 1>' \
  'Alt+1 from another workspace selects workspace 1'

run_workspace 10 0
assert_contains "$(cat "$log")" 'swaymsg <--> <workspace number 20>' \
  'Alt+0 maps workspace 10 to workspace 20'

run_workspace 20 0
assert_contains "$(cat "$log")" 'swaymsg <--> <workspace number 10>' \
  'Alt+0 maps workspace 20 back to workspace 10'

: >"$log"
assert_status 2 env PATH="$fake_bin:$PATH" SWAYMSG_LOG="$log" \
  "$workspace_helper" '1; exec touch /tmp/not-allowed'
[ ! -s "$log" ] || fail 'invalid workspace input reached swaymsg'
assert_status 2 env PATH="$fake_bin:$PATH" SWAYMSG_LOG="$log" \
  "$workspace_helper" 1 2

assert_status 41 env PATH="$fake_bin:$PATH" SWAYMSG_LOG="$log" \
  SWAYMSG_WORKSPACES_STATUS=41 "$workspace_helper" 1
assert_status 1 env PATH="$fake_bin:$PATH" SWAYMSG_LOG="$log" \
  SWAYMSG_WORKSPACES_JSON='not-json' "$workspace_helper" 1
assert_status 1 env PATH="$fake_bin:$PATH" SWAYMSG_LOG="$log" \
  SWAYMSG_WORKSPACES_JSON='[{"num":1,"focused":false}]' "$workspace_helper" 1
assert_status 1 env PATH="$fake_bin:$PATH" SWAYMSG_LOG="$log" \
  SWAYMSG_WORKSPACES_JSON='[{"num":"1; bad","focused":true}]' "$workspace_helper" 1
assert_status 42 env PATH="$fake_bin:$PATH" SWAYMSG_LOG="$log" \
  SWAYMSG_WORKSPACES_JSON='[{"num":1,"focused":true}]' \
  SWAYMSG_COMMAND_STATUS=42 "$workspace_helper" 1
assert_status 1 env PATH="$fake_bin:$PATH" SWAYMSG_LOG="$log" \
  SWAYMSG_WORKSPACES_JSON='[{"num":1,"focused":true}]' \
  SWAYMSG_COMMAND_JSON='[{"success":false,"error":"rejected"}]' "$workspace_helper" 1

: >"$log"
: >"$kitty_log"
PATH="$fake_bin:$PATH" SWAYMSG_LOG="$log" KITTY_LOG="$kitty_log" \
  SWAYMSG_TREE_JSON='{"nodes":[{"app_id":"kitty-scratchpad"}]}' \
  "$scratch_helper"
assert_contains "$(cat "$log")" \
  'swaymsg <--> <[app_id="^kitty-scratchpad$"] scratchpad show>' \
  'existing scratch terminal is shown with an exact app-id criterion'
[ ! -s "$kitty_log" ] || fail 'existing scratch terminal launched a duplicate Kitty process'

: >"$log"
: >"$kitty_log"
scratch_home="$tmp_dir/home with spaces"
mkdir -p "$scratch_home"
PATH="$fake_bin:$PATH" HOME="$scratch_home" SWAYMSG_LOG="$log" KITTY_LOG="$kitty_log" \
  SWAYMSG_TREE_JSON='{"nodes":[{"app_id":"ordinary-kitty"}]}' \
  "$scratch_helper"
expected_kitty="kitty <--class> <kitty-scratchpad> <--title> <kitty-scratchpad> <--directory> <$scratch_home>"
[ "$(cat "$kitty_log")" = "$expected_kitty" ] || \
  fail 'absent scratch terminal was not launched with literal safe arguments'

assert_status 2 env PATH="$fake_bin:$PATH" SWAYMSG_LOG="$log" KITTY_LOG="$kitty_log" \
  "$scratch_helper" unexpected
assert_status 43 env PATH="$fake_bin:$PATH" SWAYMSG_LOG="$log" KITTY_LOG="$kitty_log" \
  SWAYMSG_TREE_STATUS=43 "$scratch_helper"
assert_status 1 env PATH="$fake_bin:$PATH" SWAYMSG_LOG="$log" KITTY_LOG="$kitty_log" \
  SWAYMSG_TREE_JSON='not-json' "$scratch_helper"
assert_status 44 env PATH="$fake_bin:$PATH" HOME="$scratch_home" SWAYMSG_LOG="$log" \
  KITTY_LOG="$kitty_log" SWAYMSG_TREE_JSON='{}' KITTY_STATUS=44 "$scratch_helper"
assert_status 45 env PATH="$fake_bin:$PATH" SWAYMSG_LOG="$log" KITTY_LOG="$kitty_log" \
  SWAYMSG_TREE_JSON='{"app_id":"kitty-scratchpad"}' SWAYMSG_COMMAND_STATUS=45 \
  "$scratch_helper"
assert_status 1 env PATH="$fake_bin:$PATH" SWAYMSG_LOG="$log" KITTY_LOG="$kitty_log" \
  SWAYMSG_TREE_JSON='{"app_id":"kitty-scratchpad"}' \
  SWAYMSG_COMMAND_JSON='[{"success":false}]' "$scratch_helper"

pass 'Sway workspace and scratchpad helpers validate input and propagate failures'
