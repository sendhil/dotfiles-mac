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

cat >"$fake_bin/wezterm" <<'FAKE_WEZTERM'
#!/bin/sh
{
  printf 'wezterm'
  for arg do
    printf ' <%s>' "$arg"
  done
  printf '\n'
} >>"$WEZTERM_LOG"
if [ -n "${LOCK_PROBE_FD:-}" ] && ( eval ": >&$LOCK_PROBE_FD" ) 2>/dev/null; then
  printf 'inherited-open\n' >>"$WEZTERM_FD_LOG"
else
  printf 'closed\n' >>"$WEZTERM_FD_LOG"
fi
wezterm_status=${WEZTERM_STATUS:-0}
[ -z "${WEZTERM_STATE_DELAY:-}" ] || sleep "$WEZTERM_STATE_DELAY"
if [ "$wezterm_status" -eq 0 ] && [ -n "${SWAYMSG_TREE_STATE_FILE:-}" ]; then
  state_tmp="$SWAYMSG_TREE_STATE_FILE.tmp.$$"
  printf '%s\n' '{"nodes":[{"app_id":"wezterm-scratchpad"}]}' >"$state_tmp"
  mv "$state_tmp" "$SWAYMSG_TREE_STATE_FILE"
fi
exit "$wezterm_status"
FAKE_WEZTERM

cat >"$fake_bin/flock" <<'FAKE_FLOCK'
#!/bin/sh
[ "${FLOCK_STATUS:-0}" -eq 0 ] || exit "$FLOCK_STATUS"
if [ "$#" -eq 2 ] && [ "$1" = -u ]; then
  case $2 in ''|*[!0-9]*) exit 2 ;; esac
  eval ": >&$2" 2>/dev/null || exit 2
  rmdir "$XDG_RUNTIME_DIR/sway-scratchpad.fake-lock"
  exit $?
fi
[ "$#" -eq 4 ] || exit 2
[ "$1" = -x ] || exit 2
[ "$2" = -w ] || exit 2
timeout=$3
[ "$timeout" = 6 ] || exit 2
lock_fd=$4
case $lock_fd in ''|*[!0-9]*) exit 2 ;; esac
eval ": >&$lock_fd" 2>/dev/null || exit 2
printf 'flock <-x> <-w> <%s> <fd:%s>\n' "$timeout" "$lock_fd" >>"$FLOCK_LOG"
lock_dir="$XDG_RUNTIME_DIR/sway-scratchpad.fake-lock"
attempts=$((timeout * 20))
while ! mkdir "$lock_dir" 2>/dev/null; do
  attempts=$((attempts - 1))
  [ "$attempts" -gt 0 ] || exit 1
  sleep 0.05
done
FAKE_FLOCK
chmod +x "$fake_bin/swaymsg" "$fake_bin/wezterm" "$fake_bin/flock"

workspace_helper="$ROOT_DIR/sway/.local/bin/sway-workspace-toggle"
scratch_helper="$ROOT_DIR/sway/.local/bin/sway-scratchpad"
log="$tmp_dir/swaymsg log"
wezterm_log="$tmp_dir/wezterm log"
wezterm_fd_log="$tmp_dir/wezterm fd log"
flock_log="$tmp_dir/flock log"
: >"$log"
: >"$wezterm_log"
: >"$wezterm_fd_log"
: >"$flock_log"

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
: >"$wezterm_log"
PATH="$fake_bin:$PATH" SWAYMSG_LOG="$log" WEZTERM_LOG="$wezterm_log" \
  SWAYMSG_TREE_JSON='{"nodes":[{"app_id":"wezterm-scratchpad"}]}' \
  "$scratch_helper"
assert_contains "$(cat "$log")" \
  'swaymsg <--> <[app_id="^wezterm-scratchpad$"] scratchpad show>' \
  'existing scratch terminal is shown with an exact app-id criterion'
[ ! -s "$wezterm_log" ] || fail 'existing scratch terminal launched a duplicate WezTerm process'

: >"$log"
: >"$wezterm_log"
scratch_home="$tmp_dir/home with spaces"
runtime_dir="$tmp_dir/runtime with spaces"
mkdir -p "$scratch_home"
mkdir -p "$runtime_dir"
tree_state="$tmp_dir/tree state"
printf '%s\n' '{"nodes":[{"app_id":"org.wezfurlong.wezterm"}]}' >"$tree_state"
PATH="$fake_bin:$PATH" HOME="$scratch_home" XDG_RUNTIME_DIR="$runtime_dir" \
  SWAYMSG_LOG="$log" WEZTERM_LOG="$wezterm_log" WEZTERM_FD_LOG="$wezterm_fd_log" \
  FLOCK_LOG="$flock_log" SWAYMSG_TREE_STATE_FILE="$tree_state" LOCK_PROBE_FD=9 \
  "$scratch_helper"
expected_wezterm="wezterm <start> <--always-new-process> <--class> <wezterm-scratchpad> <--cwd> <$scratch_home>"
[ "$(cat "$wezterm_log")" = "$expected_wezterm" ] || \
  fail 'absent scratch terminal was not launched with literal safe arguments'
assert_contains "$(cat "$flock_log")" 'flock <-x> <-w> <6> <fd:' \
  'scratch helper does not acquire a bounded exclusive lock on an open descriptor'
[ "$(cat "$wezterm_fd_log")" = 'closed' ] || \
  fail 'WezTerm inherited the scratch serialization lock descriptor'

# Both invocations observe absence before one acquires the lock. The lock holder
# launches WezTerm and waits for its app_id; the waiter then rechecks and shows it.
: >"$log"
: >"$wezterm_log"
: >"$wezterm_fd_log"
: >"$flock_log"
printf '%s\n' '{"nodes":[]}' >"$tree_state"
PATH="$fake_bin:$PATH" HOME="$scratch_home" XDG_RUNTIME_DIR="$runtime_dir" \
  SWAYMSG_LOG="$log" WEZTERM_LOG="$wezterm_log" WEZTERM_FD_LOG="$wezterm_fd_log" \
  FLOCK_LOG="$flock_log" SWAYMSG_TREE_STATE_FILE="$tree_state" \
  SWAY_SCRATCHPAD_LOCKED=1 LOCK_PROBE_FD=9 \
  WEZTERM_STATE_DELAY=0.2 "$scratch_helper" &
first_pid=$!
PATH="$fake_bin:$PATH" HOME="$scratch_home" XDG_RUNTIME_DIR="$runtime_dir" \
  SWAYMSG_LOG="$log" WEZTERM_LOG="$wezterm_log" WEZTERM_FD_LOG="$wezterm_fd_log" \
  FLOCK_LOG="$flock_log" SWAYMSG_TREE_STATE_FILE="$tree_state" \
  SWAY_SCRATCHPAD_LOCKED=1 LOCK_PROBE_FD=9 \
  WEZTERM_STATE_DELAY=0.2 "$scratch_helper" &
second_pid=$!
set +e
wait "$first_pid"
first_status=$?
wait "$second_pid"
second_status=$?
set -e
[ "$first_status" -eq 0 ] || fail "first concurrent scratch invocation failed: $first_status"
[ "$second_status" -eq 0 ] || fail "second concurrent scratch invocation failed: $second_status"
[ "$(wc -l <"$wezterm_log" | tr -d ' ')" -eq 1 ] || \
  fail 'concurrent scratch invocations launched more than one WezTerm process'
assert_contains "$(cat "$log")" \
  'swaymsg <--> <[app_id="^wezterm-scratchpad$"] scratchpad show>' \
  'the concurrent waiter did not recheck and show the launched scratch terminal'
[ "$(wc -l <"$flock_log" | tr -d ' ')" -eq 2 ] || \
  fail 'a public invocation bypassed locking because an internal-looking environment variable was set'
[ "$(cat "$wezterm_fd_log")" = 'closed' ] || \
  fail 'the concurrent WezTerm child retained the serialization lock descriptor'
[ ! -e "$runtime_dir/sway-scratchpad.fake-lock" ] || \
  fail 'scratch serialization left a stale lock after both invocations exited'

assert_status 2 env PATH="$fake_bin:$PATH" SWAYMSG_LOG="$log" WEZTERM_LOG="$wezterm_log" \
  "$scratch_helper" unexpected
assert_status 43 env PATH="$fake_bin:$PATH" SWAYMSG_LOG="$log" WEZTERM_LOG="$wezterm_log" \
  SWAYMSG_TREE_STATUS=43 "$scratch_helper"
assert_status 1 env PATH="$fake_bin:$PATH" SWAYMSG_LOG="$log" WEZTERM_LOG="$wezterm_log" \
  SWAYMSG_TREE_JSON='not-json' "$scratch_helper"
printf '%s\n' '{}' >"$tree_state"
assert_status 44 env PATH="$fake_bin:$PATH" HOME="$scratch_home" SWAYMSG_LOG="$log" \
  WEZTERM_LOG="$wezterm_log" WEZTERM_FD_LOG="$wezterm_fd_log" FLOCK_LOG="$flock_log" \
  XDG_RUNTIME_DIR="$runtime_dir" \
  SWAYMSG_TREE_STATE_FILE="$tree_state" WEZTERM_STATUS=44 "$scratch_helper"
assert_status 46 env PATH="$fake_bin:$PATH" HOME="$scratch_home" SWAYMSG_LOG="$log" \
  WEZTERM_LOG="$wezterm_log" WEZTERM_FD_LOG="$wezterm_fd_log" FLOCK_LOG="$flock_log" \
  XDG_RUNTIME_DIR="$runtime_dir" \
  SWAYMSG_TREE_STATE_FILE="$tree_state" FLOCK_STATUS=46 "$scratch_helper"
assert_status 45 env PATH="$fake_bin:$PATH" SWAYMSG_LOG="$log" WEZTERM_LOG="$wezterm_log" \
  SWAYMSG_TREE_JSON='{"app_id":"wezterm-scratchpad"}' SWAYMSG_COMMAND_STATUS=45 \
  "$scratch_helper"
assert_status 1 env PATH="$fake_bin:$PATH" SWAYMSG_LOG="$log" WEZTERM_LOG="$wezterm_log" \
  SWAYMSG_TREE_JSON='{"app_id":"wezterm-scratchpad"}' \
  SWAYMSG_COMMAND_JSON='[{"success":false}]' "$scratch_helper"

pass 'Sway workspace and scratchpad helpers validate input and propagate failures'
