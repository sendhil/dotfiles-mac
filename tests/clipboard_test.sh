#!/bin/bash

set -eu

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$TEST_DIR/.." && pwd)
. "$TEST_DIR/test_helper.sh"

helper="$ROOT_DIR/bin/.local/bin/dotfiles-copy"
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM

[ -x "$helper" ] || fail 'dotfiles-copy is missing or not executable'

fake_bin="$tmp_dir/fake commands"
mkdir -p "$fake_bin"

cat >"$fake_bin/pbcopy" <<'FAKE_PBCOPY'
#!/bin/sh
printf '%s\n' "$#" >"$COPY_ARGC_LOG"
printf 'pbcopy\n' >"$COPY_TRANSPORT_LOG"
cat >"$COPY_DATA_LOG"
exit "${COPY_STATUS:-0}"
FAKE_PBCOPY

cat >"$fake_bin/wl-copy" <<'FAKE_WL_COPY'
#!/bin/sh
printf '%s\n' "$#" >"$COPY_ARGC_LOG"
printf 'wl-copy\n' >"$COPY_TRANSPORT_LOG"
cat >"$COPY_DATA_LOG"
exit "${COPY_STATUS:-0}"
FAKE_WL_COPY

chmod +x "$fake_bin/pbcopy" "$fake_bin/wl-copy"

input="$tmp_dir/input data"
printf 'first line\nsecond line without a final newline' >"$input"

darwin_log="$tmp_dir/darwin clipboard"
darwin_argc="$tmp_dir/darwin argc"
darwin_transport="$tmp_dir/darwin transport"
PATH="$fake_bin:/usr/bin:/bin" DOTFILES_UNAME=Darwin WAYLAND_DISPLAY=wayland-test \
  COPY_DATA_LOG="$darwin_log" COPY_ARGC_LOG="$darwin_argc" COPY_TRANSPORT_LOG="$darwin_transport" \
  "$helper" <"$input"
cmp "$input" "$darwin_log" >/dev/null || fail 'Darwin clipboard changed stdin bytes'
[ "$(cat "$darwin_argc")" -eq 0 ] || fail 'pbcopy received unexpected arguments'
[ "$(cat "$darwin_transport")" = pbcopy ] || fail 'Darwin did not select pbcopy first'

wayland_log="$tmp_dir/wayland clipboard"
wayland_argc="$tmp_dir/wayland argc"
wayland_transport="$tmp_dir/wayland transport"
PATH="$fake_bin:/usr/bin:/bin" DOTFILES_UNAME=Linux WAYLAND_DISPLAY=wayland-1 \
  COPY_DATA_LOG="$wayland_log" COPY_ARGC_LOG="$wayland_argc" COPY_TRANSPORT_LOG="$wayland_transport" \
  "$helper" <"$input"
cmp "$input" "$wayland_log" >/dev/null || fail 'Wayland clipboard changed stdin bytes'
[ "$(cat "$wayland_argc")" -eq 0 ] || fail 'wl-copy received unexpected arguments'
[ "$(cat "$wayland_transport")" = wl-copy ] || fail 'local Wayland did not select wl-copy'

set +e
PATH="$fake_bin:/usr/bin:/bin" DOTFILES_UNAME=Darwin COPY_STATUS=23 \
  COPY_DATA_LOG="$tmp_dir/failed clipboard" COPY_ARGC_LOG="$tmp_dir/failed argc" \
  COPY_TRANSPORT_LOG="$tmp_dir/failed transport" \
  "$helper" <"$input" >/dev/null 2>"$tmp_dir/command-error"
command_status=$?
set -e
[ "$command_status" -eq 23 ] || fail "clipboard command failure was not preserved (got $command_status)"

set +e
PATH="$fake_bin:/usr/bin:/bin" DOTFILES_UNAME=Linux WAYLAND_DISPLAY=wayland-1 COPY_STATUS=29 \
  COPY_DATA_LOG="$tmp_dir/failed wayland clipboard" COPY_ARGC_LOG="$tmp_dir/failed wayland argc" \
  COPY_TRANSPORT_LOG="$tmp_dir/failed wayland transport" \
  "$helper" <"$input" >/dev/null 2>"$tmp_dir/wayland-command-error"
wayland_command_status=$?
set -e
[ "$wayland_command_status" -eq 29 ] || fail "Wayland command failure was not preserved (got $wayland_command_status)"

osc_input="$tmp_dir/osc input"
printf 'ssh line one\nssh line two\n' >"$osc_input"
osc_tty="$tmp_dir/tty with spaces; touch should-not-run"
: >"$osc_tty"
PATH=/usr/bin:/bin DOTFILES_UNAME=Linux WAYLAND_DISPLAY= SSH_CONNECTION='host 1 host 2' \
  DOTFILES_TTY="$osc_tty" "$helper" <"$osc_input"
payload=$(base64 <"$osc_input" | tr -d '\n')
printf '\033]52;c;%s\a' "$payload" >"$tmp_dir/expected osc"
cmp "$tmp_dir/expected osc" "$osc_tty" >/dev/null || fail 'OSC 52 output did not faithfully encode stdin'
[ ! -e "$tmp_dir/should-not-run" ] || fail 'DOTFILES_TTY executed shell syntax'

missing_tty="$tmp_dir/missing parent/tty"
set +e
error=$(PATH=/usr/bin:/bin DOTFILES_UNAME=Linux WAYLAND_DISPLAY= DOTFILES_TTY="$missing_tty" \
  "$helper" <"$input" 2>&1)
missing_status=$?
set -e
[ "$missing_status" -ne 0 ] || fail 'missing clipboard transport reported success'
assert_contains "$error" 'no clipboard transport is available' 'missing clipboard transport has a clear error'
[ ! -e "$missing_tty" ] || fail 'missing clipboard target was unexpectedly created'

unwritable_tty="$tmp_dir/not a tty"
mkdir "$unwritable_tty"
set +e
error=$(PATH=/usr/bin:/bin DOTFILES_UNAME=Linux WAYLAND_DISPLAY= DOTFILES_TTY="$unwritable_tty" \
  "$helper" <"$input" 2>&1)
unwritable_status=$?
set -e
[ "$unwritable_status" -ne 0 ] || fail 'unwritable clipboard transport reported success'
assert_contains "$error" 'no clipboard transport is available' 'unwritable clipboard transport has a clear error'

tmux_config=$(cat "$ROOT_DIR/tmux/.tmux.conf")
assert_contains "$tmux_config" 'set-clipboard on' 'tmux keeps terminal clipboard integration enabled'
copy_bindings=$(printf '%s\n' "$tmux_config" | grep -c "copy-pipe-and-cancel '~/.local/bin/dotfiles-copy'" || true)
[ "$copy_bindings" -eq 3 ] || fail "tmux does not route all three copy bindings through dotfiles-copy"
if rg -n "copy-pipe-and-cancel ['\"]?pbcopy" "$ROOT_DIR/tmux/.tmux.conf" >/dev/null; then
  fail 'tmux still invokes pbcopy directly'
fi

if rg -n '^[[:space:]]*copy_command\b|\bpbcopy\b' "$ROOT_DIR/zellij/.config/zellij/config.kdl" >/dev/null; then
  fail 'Zellij still overrides its OSC 52 clipboard behavior'
fi

pass 'clipboard transport selection is portable and preserves stdin'
