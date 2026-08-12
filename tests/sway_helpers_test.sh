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
    if [ -n "${SWAYMSG_TREE_STATE_FILE:-}" ]; then
      cat "$SWAYMSG_TREE_STATE_FILE"
    elif [ "${SWAYMSG_TREE_JSON+set}" = set ]; then
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
kitty_status=${KITTY_STATUS:-0}
[ -z "${KITTY_STATE_DELAY:-}" ] || sleep "$KITTY_STATE_DELAY"
if [ "$kitty_status" -eq 0 ] && [ -n "${SWAYMSG_TREE_STATE_FILE:-}" ]; then
  state_tmp="$SWAYMSG_TREE_STATE_FILE.tmp.$$"
  printf '%s\n' '{"nodes":[{"app_id":"kitty-scratchpad"}]}' >"$state_tmp"
  mv "$state_tmp" "$SWAYMSG_TREE_STATE_FILE"
fi
exit "$kitty_status"
FAKE_KITTY

cat >"$fake_bin/flock" <<'FAKE_FLOCK'
#!/bin/sh
[ "${FLOCK_STATUS:-0}" -eq 0 ] || exit "$FLOCK_STATUS"
[ "$#" -ge 5 ] || exit 2
[ "$1" = -x ] || exit 2
[ "$2" = -w ] || exit 2
timeout=$3
lock_file=$4
shift 4
lock_dir="$lock_file.fake-lock"
attempts=$((timeout * 20))
while ! mkdir "$lock_dir" 2>/dev/null; do
  attempts=$((attempts - 1))
  [ "$attempts" -gt 0 ] || exit 1
  sleep 0.05
done
trap 'rmdir "$lock_dir"' EXIT HUP INT TERM
set +e
"$@"
status=$?
set -e
exit "$status"
FAKE_FLOCK
chmod +x "$fake_bin/swaymsg" "$fake_bin/kitty" "$fake_bin/flock"

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
assert_status 1 env PATH="$fake_bin:$PATH" SWAYMSG_LOG="$log" \
  SWAYMSG_WORKSPACES_JSON='[{"num":"1","focused":true}]' "$workspace_helper" 1
assert_status 1 env PATH="$fake_bin:$PATH" SWAYMSG_LOG="$log" \
  SWAYMSG_WORKSPACES_JSON='{"nested":[{"num":1,"focused":true}]}' "$workspace_helper" 1
assert_status 1 env PATH="$fake_bin:$PATH" SWAYMSG_LOG="$log" \
  SWAYMSG_WORKSPACES_JSON='[{"num":0,"focused":true}]' "$workspace_helper" 1
assert_status 1 env PATH="$fake_bin:$PATH" SWAYMSG_LOG="$log" \
  SWAYMSG_WORKSPACES_JSON='[{"num":-1,"focused":true}]' "$workspace_helper" 1
assert_status 1 env PATH="$fake_bin:$PATH" SWAYMSG_LOG="$log" \
  SWAYMSG_WORKSPACES_JSON='[{"num":1.5,"focused":true}]' "$workspace_helper" 1
assert_status 1 env PATH="$fake_bin:$PATH" SWAYMSG_LOG="$log" \
  SWAYMSG_WORKSPACES_JSON='[{"num":1,"focused":true},{"num":2,"focused":true}]' \
  "$workspace_helper" 1
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
runtime_dir="$tmp_dir/runtime with spaces"
mkdir -p "$scratch_home"
mkdir -p "$runtime_dir"
tree_state="$tmp_dir/tree state"
printf '%s\n' '{"nodes":[{"app_id":"ordinary-kitty"}]}' >"$tree_state"
PATH="$fake_bin:$PATH" HOME="$scratch_home" XDG_RUNTIME_DIR="$runtime_dir" \
  SWAYMSG_LOG="$log" KITTY_LOG="$kitty_log" SWAYMSG_TREE_STATE_FILE="$tree_state" \
  "$scratch_helper"
expected_kitty="kitty <--class> <kitty-scratchpad> <--title> <kitty-scratchpad> <--directory> <$scratch_home>"
[ "$(cat "$kitty_log")" = "$expected_kitty" ] || \
  fail 'absent scratch terminal was not launched with literal safe arguments'

# Both invocations observe absence before one acquires the lock. The lock holder
# launches Kitty and waits for its app_id; the waiter then rechecks and shows it.
: >"$log"
: >"$kitty_log"
printf '%s\n' '{"nodes":[]}' >"$tree_state"
PATH="$fake_bin:$PATH" HOME="$scratch_home" XDG_RUNTIME_DIR="$runtime_dir" \
  SWAYMSG_LOG="$log" KITTY_LOG="$kitty_log" SWAYMSG_TREE_STATE_FILE="$tree_state" \
  KITTY_STATE_DELAY=0.2 "$scratch_helper" &
first_pid=$!
PATH="$fake_bin:$PATH" HOME="$scratch_home" XDG_RUNTIME_DIR="$runtime_dir" \
  SWAYMSG_LOG="$log" KITTY_LOG="$kitty_log" SWAYMSG_TREE_STATE_FILE="$tree_state" \
  KITTY_STATE_DELAY=0.2 "$scratch_helper" &
second_pid=$!
set +e
wait "$first_pid"
first_status=$?
wait "$second_pid"
second_status=$?
set -e
[ "$first_status" -eq 0 ] || fail "first concurrent scratch invocation failed: $first_status"
[ "$second_status" -eq 0 ] || fail "second concurrent scratch invocation failed: $second_status"
[ "$(wc -l <"$kitty_log" | tr -d ' ')" -eq 1 ] || \
  fail 'concurrent scratch invocations launched more than one Kitty process'
assert_contains "$(cat "$log")" \
  'swaymsg <--> <[app_id="^kitty-scratchpad$"] scratchpad show>' \
  'the concurrent waiter did not recheck and show the launched scratch terminal'
[ ! -e "$runtime_dir/sway-scratchpad.lock.fake-lock" ] || \
  fail 'scratch serialization left a stale lock after both invocations exited'

assert_status 2 env PATH="$fake_bin:$PATH" SWAYMSG_LOG="$log" KITTY_LOG="$kitty_log" \
  "$scratch_helper" unexpected
assert_status 43 env PATH="$fake_bin:$PATH" SWAYMSG_LOG="$log" KITTY_LOG="$kitty_log" \
  SWAYMSG_TREE_STATUS=43 "$scratch_helper"
assert_status 1 env PATH="$fake_bin:$PATH" SWAYMSG_LOG="$log" KITTY_LOG="$kitty_log" \
  SWAYMSG_TREE_JSON='not-json' "$scratch_helper"
printf '%s\n' '{}' >"$tree_state"
assert_status 44 env PATH="$fake_bin:$PATH" HOME="$scratch_home" SWAYMSG_LOG="$log" \
  KITTY_LOG="$kitty_log" XDG_RUNTIME_DIR="$runtime_dir" \
  SWAYMSG_TREE_STATE_FILE="$tree_state" KITTY_STATUS=44 "$scratch_helper"
assert_status 46 env PATH="$fake_bin:$PATH" HOME="$scratch_home" SWAYMSG_LOG="$log" \
  KITTY_LOG="$kitty_log" XDG_RUNTIME_DIR="$runtime_dir" \
  SWAYMSG_TREE_STATE_FILE="$tree_state" FLOCK_STATUS=46 "$scratch_helper"
assert_status 45 env PATH="$fake_bin:$PATH" SWAYMSG_LOG="$log" KITTY_LOG="$kitty_log" \
  SWAYMSG_TREE_JSON='{"app_id":"kitty-scratchpad"}' SWAYMSG_COMMAND_STATUS=45 \
  "$scratch_helper"
assert_status 1 env PATH="$fake_bin:$PATH" SWAYMSG_LOG="$log" KITTY_LOG="$kitty_log" \
  SWAYMSG_TREE_JSON='{"app_id":"kitty-scratchpad"}' \
  SWAYMSG_COMMAND_JSON='[{"success":false}]' "$scratch_helper"

pass 'Sway workspace and scratchpad helpers validate input and propagate failures'
