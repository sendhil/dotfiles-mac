#!/bin/bash

set -eu

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$TEST_DIR/.." && pwd)
. "$TEST_DIR/test_helper.sh"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM

fake_bin="$tmp_dir/fake bin"
mkdir -p "$fake_bin"

cat >"$fake_bin/colima" <<'FAKE_COLIMA'
#!/bin/sh

{
  printf 'colima'
  for arg do
    printf ' <%s>' "$arg"
  done
  printf '\n'
} >>"$COLIMA_LOG"

command_name=${1-}
case $command_name in
  list)
    printf '%s\n' 'PROFILE STATUS ARCH CPUS MEMORY DISK RUNTIME ADDRESS'
    if [ "${COLIMA_PROFILE_PRESENT:-1}" -eq 1 ]; then
      printf '%s\n' 'neovim-dev Running aarch64 2 4GiB 20GiB docker 127.0.0.1'
    fi
    ;;
  ssh)
    shift
    [ "${1-}" = -p ] || exit 91
    [ "${2-}" = neovim-dev ] || exit 92
    shift 2
    if [ "${1-}" = -- ]; then
      shift
      if [ "$#" -eq 3 ] && [ "$1" = command ] && [ "$2" = -v ] && [ "$3" = nvim ]; then
        exit "${COLIMA_NVIM_STATUS:-0}"
      fi
      if [ "$#" -eq 3 ] && [ "$1" = test ] && [ "$2" = -d ] && \
        [ "$3" = /home/dotfiles/neovim/.config/nvim ]; then
        exit "${COLIMA_MOUNT_STATUS:-0}"
      fi
      exit 93
    fi
    [ "$#" -eq 0 ] || exit 97
    cat >"$COLIMA_GUEST_CONFIG_LOG"
    printf '%s\n' guest-config >>"$COLIMA_MUTATION_LOG"
    ;;
  start|stop|delete)
    printf '%s\n' "$command_name" >>"$COLIMA_MUTATION_LOG"
    ;;
  *)
    exit 98
    ;;
esac
FAKE_COLIMA

chmod +x "$fake_bin/colima"

setup_script="$ROOT_DIR/scripts/setup-colima-neovim.sh"
absent_home="$tmp_dir/absent guest home"
mkdir -p "$absent_home"
: >"$tmp_dir/absent colima log"
: >"$tmp_dir/absent mutation log"
: >"$tmp_dir/absent guest config"
set +e
absent_output=$(PATH="$fake_bin:/usr/bin:/bin" HOME="$absent_home" \
  COLIMA_LOG="$tmp_dir/absent colima log" \
  COLIMA_MUTATION_LOG="$tmp_dir/absent mutation log" \
  COLIMA_GUEST_CONFIG_LOG="$tmp_dir/absent guest config" \
  COLIMA_PROFILE_PRESENT=0 \
  "$setup_script" 2>&1)
absent_status=$?
set -e
[ "$absent_status" -ne 0 ] || fail 'Colima setup created a guest owned by external provisioning'
assert_contains "$absent_output" pre-provisioned \
  'absent-profile error does not explain the external ownership boundary'
[ ! -s "$tmp_dir/absent mutation log" ] || \
  fail 'absent Colima profile triggered lifecycle or guest mutation'
[ ! -e "$absent_home/.local/bin/colima-nvim" ] || \
  fail 'absent Colima profile installed a local helper'

readme=$(cat "$ROOT_DIR/README.md")
assert_contains "$readme" 'pre-provisioned `neovim-dev`' \
  'README does not state the Colima guest ownership prerequisite'
assert_contains "$readme" '/home/dotfiles' \
  'README does not document the required dotfiles guest mount'

missing_home="$tmp_dir/missing nvim home"
mkdir -p "$missing_home"
: >"$tmp_dir/missing colima log"
: >"$tmp_dir/missing mutation log"
: >"$tmp_dir/missing guest config"
set +e
missing_output=$(PATH="$fake_bin:/usr/bin:/bin" HOME="$missing_home" \
  COLIMA_LOG="$tmp_dir/missing colima log" \
  COLIMA_MUTATION_LOG="$tmp_dir/missing mutation log" \
  COLIMA_GUEST_CONFIG_LOG="$tmp_dir/missing guest config" \
  COLIMA_NVIM_STATUS=1 \
  "$setup_script" 2>&1)
missing_status=$?
set -e
[ "$missing_status" -ne 0 ] || fail 'Colima setup accepted a guest without Neovim'
assert_contains "$missing_output" neovim-dev 'missing-prerequisite error does not name the expected guest'
assert_contains "$missing_output" nvim 'missing-prerequisite error does not name Neovim'
assert_contains "$missing_output" pre-provisioned \
  'missing-prerequisite error does not explain the external ownership boundary'
[ ! -s "$tmp_dir/missing mutation log" ] || \
  fail 'missing guest Neovim triggered Colima or guest mutation'
[ ! -e "$missing_home/.local/bin/colima-nvim" ] || \
  fail 'missing guest Neovim installed a local helper before preflight passed'

missing_mount_home="$tmp_dir/missing mount home"
mkdir -p "$missing_mount_home"
: >"$tmp_dir/missing mount colima log"
: >"$tmp_dir/missing mount mutation log"
: >"$tmp_dir/missing mount guest config"
set +e
missing_mount_output=$(PATH="$fake_bin:/usr/bin:/bin" HOME="$missing_mount_home" \
  COLIMA_LOG="$tmp_dir/missing mount colima log" \
  COLIMA_MUTATION_LOG="$tmp_dir/missing mount mutation log" \
  COLIMA_GUEST_CONFIG_LOG="$tmp_dir/missing mount guest config" \
  COLIMA_NVIM_STATUS=0 COLIMA_MOUNT_STATUS=1 \
  "$setup_script" 2>&1)
missing_mount_status=$?
set -e
[ "$missing_mount_status" -ne 0 ] || fail 'Colima setup accepted a guest without its dotfiles mount'
assert_contains "$missing_mount_output" /home/dotfiles \
  'missing-mount error does not name the required guest mount'
[ ! -s "$tmp_dir/missing mount mutation log" ] || \
  fail 'missing dotfiles guest mount triggered Colima or guest mutation'
[ ! -e "$missing_mount_home/.local/bin/colima-nvim" ] || \
  fail 'missing dotfiles guest mount installed a local helper before preflight passed'

configured_home="$tmp_dir/configured guest home"
mkdir -p "$configured_home"
: >"$tmp_dir/configured colima log"
: >"$tmp_dir/configured mutation log"
: >"$tmp_dir/configured guest config"
configured_output=$(PATH="$fake_bin:/usr/bin:/bin" HOME="$configured_home" \
  COLIMA_LOG="$tmp_dir/configured colima log" \
  COLIMA_MUTATION_LOG="$tmp_dir/configured mutation log" \
  COLIMA_GUEST_CONFIG_LOG="$tmp_dir/configured guest config" \
  COLIMA_NVIM_STATUS=0 \
  "$setup_script" 2>&1)

if grep -Eq '^(start|stop|delete)$' "$tmp_dir/configured mutation log"; then
  fail 'configured existing Colima guest was stopped, deleted, or recreated'
fi
[ "$(cat "$tmp_dir/configured mutation log")" = guest-config ] || \
  fail 'configured guest did not proceed to Neovim configuration'
guest_config=$(cat "$tmp_dir/configured guest config")
assert_contains "$guest_config" \
  'ln -sf /home/dotfiles/neovim/.config/nvim ~/.config/nvim' \
  'configured guest did not link the mounted Neovim configuration'
[ -x "$configured_home/.local/bin/colima-nvim" ] || \
  fail 'configured guest did not install the local Colima helper'
assert_contains "$configured_output" 'Colima VM setup complete' \
  'configured guest did not report successful completion'

configured_calls=$(cat "$tmp_dir/configured colima log")
assert_contains "$configured_calls" 'colima <list>' 'Colima setup did not inspect existing profiles'
assert_contains "$configured_calls" \
  'colima <ssh> <-p> <neovim-dev> <--> <command> <-v> <nvim>' \
  'Colima setup did not preflight guest Neovim with literal arguments'
assert_contains "$configured_calls" \
  'colima <ssh> <-p> <neovim-dev> <--> <test> <-d> </home/dotfiles/neovim/.config/nvim>' \
  'Colima setup did not preflight its required guest mount with literal arguments'
if printf '%s\n' "$configured_calls" | grep -Eq \
  'colima <(start|stop|delete)>|<--force>'; then
  fail 'Colima setup contains a destructive existing-profile lifecycle'
fi

pass 'Colima setup preserves provisioned guests and preflights Neovim before mutation'
