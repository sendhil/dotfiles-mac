#!/bin/bash

set -eu

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$TEST_DIR/.." && pwd)
. "$TEST_DIR/test_helper.sh"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM
mkdir -p "$tmp_dir/bin" "$tmp_dir/home"
printf 'original zsh configuration\n' >"$tmp_dir/home/.zshrc"
before=$(cksum "$tmp_dir/home/.zshrc")

cat >"$tmp_dir/bin/stow" <<'FAKE_STOW'
#!/bin/sh
printf '%s\n' "$@" >"$STOW_LOG"
exit 1
FAKE_STOW
chmod +x "$tmp_dir/bin/stow"

set +e
PATH="$tmp_dir/bin:$PATH" STOW_LOG="$tmp_dir/stow.log" \
  "$ROOT_DIR/scripts/stow-preflight.sh" ubuntu "$tmp_dir/home" \
  >"$tmp_dir/stdout" 2>"$tmp_dir/stderr"
status=$?
set -e

[ "$status" -eq 1 ] || fail "preflight did not preserve Stow conflict status (got $status)"
argv=$(tr '\n' ' ' <"$tmp_dir/stow.log")
assert_contains "$argv" --simulate 'preflight invokes Stow simulation'
assert_contains "$argv" --no-folding 'preflight disables directory folding'
assert_contains "$argv" "$tmp_dir/home" 'preflight passes the requested target'
assert_contains "$argv" sway 'preflight passes Ubuntu packages'
assert_not_contains "$argv" --delete 'preflight never deletes'
assert_not_contains "$argv" --restow 'preflight never restows'
after=$(cksum "$tmp_dir/home/.zshrc")
[ "$before" = "$after" ] || fail 'preflight changed an existing target file'

assert_status 2 "$ROOT_DIR/scripts/stow-preflight.sh" ubuntu "$tmp_dir/missing"
assert_status 2 "$ROOT_DIR/scripts/stow-preflight.sh" ubuntu

pass 'preflight is read-only and preserves Stow status'

make_tmp=$(mktemp -d)
trap 'rm -rf "$tmp_dir" "$make_tmp"' EXIT HUP INT TERM
mkdir -p "$make_tmp/bin" "$make_tmp/home"
cat >"$make_tmp/bin/stow" <<'FAKE_MAKE_STOW'
#!/bin/sh
printf 'call\n' >>"$STOW_LOG"
printf '%s\n' "$@" >>"$STOW_LOG"
FAKE_MAKE_STOW
chmod +x "$make_tmp/bin/stow"

set +e
PATH="$make_tmp/bin:$PATH" STOW_LOG="$make_tmp/stow.log" \
  make --no-print-directory -s -C "$ROOT_DIR" stow TARGET="$make_tmp/home" \
  >"$make_tmp/stdout" 2>"$make_tmp/stderr"
make_stow_status=$?
set -e
[ "$make_stow_status" -eq 2 ] || fail "bare make stow should fail with status 2 (got $make_stow_status)"
make_error=$(cat "$make_tmp/stdout" "$make_tmp/stderr")
assert_contains "$make_error" 'stow-macos' 'bare make stow names the macOS replacement'
assert_contains "$make_error" 'stow-ubuntu' 'bare make stow names the Ubuntu replacement'

: >"$make_tmp/stow.log"
PATH="$make_tmp/bin:$PATH" STOW_LOG="$make_tmp/stow.log" \
  make --no-print-directory -s -C "$ROOT_DIR" stow-ubuntu TARGET="$make_tmp/home"
calls=$(grep -c '^call$' "$make_tmp/stow.log")
[ "$calls" -eq 2 ] || fail "stow-ubuntu should invoke simulation and mutation (got $calls calls)"
first_call=$(sed -n '/^call$/{n;p;}' "$make_tmp/stow.log" | sed -n '1p')
[ "$first_call" = '--simulate' ] || fail 'stow-ubuntu does not run preflight first'

assert_status 2 make --no-print-directory -s -C "$ROOT_DIR" stow-docs TARGET="$make_tmp/home"
assert_status 2 make --no-print-directory -s -C "$ROOT_DIR" stow-not-a-package TARGET="$make_tmp/home"

pass 'Make exposes explicit platform targets'

target_injection='TARGET="; printf TARGET_INJECTION; #'
: >"$make_tmp/stow.log"
set +e
target_output=$(PATH="$make_tmp/bin:$PATH" STOW_LOG="$make_tmp/stow.log" \
  make --no-print-directory -s -C "$ROOT_DIR" preflight-ubuntu "$target_injection" \
  2>"$make_tmp/target-preflight.stderr")
target_status=$?
set -e
[ "$target_status" -ne 0 ] || fail 'TARGET injection turned preflight failure into success'
assert_not_contains "$target_output" TARGET_INJECTION 'TARGET value executed as shell source'
[ ! -s "$make_tmp/stow.log" ] || fail 'invalid TARGET reached Stow during preflight'

: >"$make_tmp/stow.log"
set +e
target_output=$(PATH="$make_tmp/bin:$PATH" STOW_LOG="$make_tmp/stow.log" \
  make --no-print-directory -s -C "$ROOT_DIR" stow-ubuntu "$target_injection" \
  2>"$make_tmp/target-stow.stderr")
target_status=$?
set -e
[ "$target_status" -ne 0 ] || fail 'TARGET injection bypassed the mutating target preflight'
assert_not_contains "$target_output" TARGET_INJECTION 'mutating target executed TARGET as shell source'
[ ! -s "$make_tmp/stow.log" ] || fail 'Stow mutation followed invalid TARGET preflight'

quoted_target="$make_tmp/home with a \"quote"
mkdir -p "$quoted_target"
: >"$make_tmp/stow.log"
PATH="$make_tmp/bin:$PATH" STOW_LOG="$make_tmp/stow.log" \
  make --no-print-directory -s -C "$ROOT_DIR" stow-ubuntu TARGET="$quoted_target"
quoted_target_count=$(grep -Fxc -- "$quoted_target" "$make_tmp/stow.log")
[ "$quoted_target_count" -eq 2 ] || fail 'TARGET containing spaces and a quote was not passed literally'

stem_injection='stow-bin" ]; then printf PWN; exit 0; fi; #'
set +e
stem_output=$(make --no-print-directory -s -C "$ROOT_DIR" "$stem_injection" 2>&1)
stem_status=$?
set -e
[ "$stem_status" -ne 0 ] || fail 'stow pattern stem executed as shell source'
[ "$stem_output" != 'PWN' ] || fail 'stow pattern stem printed its injected payload'

stem_injection='unstow-bin" ]; then printf PWN; exit 0; fi; #'
set +e
stem_output=$(make --no-print-directory -s -C "$ROOT_DIR" "$stem_injection" 2>&1)
stem_status=$?
set -e
[ "$stem_status" -ne 0 ] || fail 'unstow pattern stem executed as shell source'
[ "$stem_output" != 'PWN' ] || fail 'unstow pattern stem printed its injected payload'

pass 'Make treats target paths and package names as literal data'
